// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IModeratioWithConsumer} from "./IModeratioWithConsumer.sol";
import {IRuler} from "./IRuler.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import "@chainlink/v0.8/ChainlinkClient.sol";
import "@chainlink/v0.8/ConfirmedOwner.sol";

contract ModeratioWithConsumer is IModeratioWithConsumer, ChainlinkClient, ConfirmedOwner {
    uint256 public constant MAX_DEADLINE = 3 days;

    using Chainlink for Chainlink.Request;

    /**
     * Chainlink anyAPI related variables
     */
    uint256 public caseResult;
    bytes32 private jobId;
    uint256 private fee;

    uint256 public currentCaseId = 0;
    mapping(uint256 => Case) public cases;
    mapping(bytes32 => uint256) public requestIdToCaseId;

    enum CaseStatus {
        NONE,
        CREATED,
        EXECUTED
    }

    struct Case {
        CaseStatus status;
        IRuler rulingContract;
        // chainlink functions
        bytes32 requestId;
        uint256 result;
        bytes error;
        // ruling
        mapping(address => ContextStatus) contextProviders;
        uint256 totalContextProvidersWaiting;
        uint256 deadline;
    }

    enum ContextStatus {
        NOT_SELECTED,
        SELECTED,
        DROPPED_THE_MIC
    }

    uint64 public subscriptionId;
    uint32 public gasLimit;

    bytes32 public sourceCodeHash;
    bytes32 public secretsHash;

    event NewCase(uint256 indexed caseId, address rulingContract);
    event DroppedTheMic(uint256 indexed caseId, address contextProvider);
    event CaseRuled(uint256 indexed caseId, uint256 result);

    error CaseDoesNotExist(uint256 caseId);
    error CaseInWrongStatus(uint256 caseId, CaseStatus desiredStatus);
    error CaseNotReadyToExecute(uint256 caseId);
    error CaseIsReadyToExecute(uint256 caseId);
    error DuplicateParticipant(address dup);
    error ContextProviderNotSelected(uint256 caseId, address provider);
    error SourceCodeHashMismatch();
    error SecretsHashMismatch();

    event DataFullfilled(bytes32 indexed requestId, uint256 volume);

    /**
     * @notice Initialize the link token and target oracle
     *
     * Sepolia Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Oracle: 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3 (oracle on mumbai testnet)
     * jobId: ca98366cc7314957b8c012c72f05aeeb
     *
     */
    constructor(address _oracle, bytes32 _jobId, address _link) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function getCaseContextProviderStatus(uint256 caseId, address participant) public view returns (ContextStatus) {
        return cases[caseId].contextProviders[participant];
    }

    function createCase(address[] memory participants, IRuler rulingContract)
        external
        override
        returns (uint256 caseId)
    {
        caseId = currentCaseId++;
        Case storage currentCase = cases[caseId];
        currentCase.status = CaseStatus.CREATED;
        currentCase.rulingContract = rulingContract;
        currentCase.totalContextProvidersWaiting = participants.length;
        // solhint-disable-next-line not-rely-on-time
        currentCase.deadline = block.timestamp + MAX_DEADLINE;

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            if (currentCase.contextProviders[participant] != ContextStatus.NOT_SELECTED) {
                revert DuplicateParticipant(participant);
            }

            currentCase.contextProviders[participant] = ContextStatus.SELECTED;
        }

        emit NewCase(caseId, address(rulingContract));
    }

    function dropTheMic(uint256 caseId) public {
        Case storage currentCase = cases[caseId];
        if (currentCase.status != CaseStatus.CREATED) {
            revert CaseInWrongStatus(caseId, CaseStatus.CREATED);
        }
        if (isCaseReadyToExecute(caseId)) {
            revert CaseIsReadyToExecute(caseId);
        }
        if (currentCase.contextProviders[msg.sender] != ContextStatus.SELECTED) {
            revert ContextProviderNotSelected(caseId, msg.sender);
        }
        currentCase.contextProviders[msg.sender] = ContextStatus.DROPPED_THE_MIC;
        currentCase.totalContextProvidersWaiting--;
        if (currentCase.totalContextProvidersWaiting == 0) {
            request(caseId);
        }

        emit DroppedTheMic(caseId, msg.sender);
    }

    /**
     * @notice Creates a Chainlink request to retrieve the case result
     * achieved by gpt-3
     * @return requestId - id of the request
     */
    function request(uint256 caseId) public returns (bytes32 requestId) {
        if (!isCaseReadyToExecute(caseId)) {
            revert CaseNotReadyToExecute(caseId);
        }
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        string memory url =
            string(abi.encodePacked("https://front-end-navy-three.vercel.app/api/get-context?caseId=", caseId));
        req.add("get", url);

        req.add("path", "result");
        req.addInt("times", 1);

        requestId = sendChainlinkRequest(req, (1 * LINK_DIVISIBILITY) / 10); // 0,1*10**18 LINK
        requestIdToCaseId[requestId] = caseId;
        return requestId;
    }

    /**
     * @notice Receives the response in the form of uint256
     *
     * @param requestId - id of the request
     * @param  result- response, the index of the outcome that GPT-3 chose from the outcomes list
     */
    function fulfill(bytes32 requestId, uint256 result) public recordChainlinkFulfillment(requestId) {
        _executeRuling(requestIdToCaseId[requestId], result);
        emit DataFullfilled(requestId, result);
    }

    function _executeRuling(uint256 caseId, uint256 result) internal {
        // CHECKS
        Case storage currentCase = cases[caseId];
        if (!isCaseReadyToExecute(caseId)) {
            revert CaseNotReadyToExecute(caseId);
        }
        // EFFECTS
        currentCase.result = result;
        currentCase.status = CaseStatus.EXECUTED;

        // INTERACTIONS
        currentCase.rulingContract.rule(caseId, result);

        emit CaseRuled(caseId, result);
    }

    function isCaseReadyToExecute(uint256 caseId) public view returns (bool) {
        Case storage currentCase = cases[caseId];
        return
        // solhint-disable-next-line not-rely-on-time
        (block.timestamp > currentCase.deadline || currentCase.totalContextProvidersWaiting == 0)
            && currentCase.status == CaseStatus.CREATED;
    }
}
