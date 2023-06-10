// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IModeratioConsumer} from "./IModeratioConsumer.sol";
import {IRuler} from "./IRuler.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract ModeratioConsumer is IModeratioConsumer, Ownable {

    uint256 public constant MAX_DEADLINE = 3 days;

    uint256 public currentCaseId = 0;
    mapping(uint256 => Case) public cases;
    mapping(bytes32 => uint256) public requestIdToCaseId;

    enum CaseStatus {
        NONE,
        CREATED,
        REQUESTED,
        READY_TO_EXECUTE,
        EXECUTED
    }

    struct Case {
        CaseStatus status;
        IRuler rulingContract;
        // chainlink functions
        bytes32 requestId;
        bytes response;
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
    error ContextProviderNotSelected(uint256 caseId, address provider);
    error SourceCodeHashMismatch();
    error SecretsHashMismatch();

    constructor(
        address oracle,
        uint64 _subscriptionId,
        uint32 _gasLimit
    ) {
        
    }

    // we update only the hash and check for it
    function setRequest(
        string calldata source,
        bytes calldata secrets
    ) public onlyOwner {
        sourceCodeHash = keccak256(bytes(source));
        secretsHash = keccak256(secrets);
    }

    function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function setGasLimit(uint32 _gasLimit) public onlyOwner {
        gasLimit = _gasLimit;
    }



    function createCase(
        address[] memory participants,
        IRuler rulingContract
    ) external override returns (uint256 caseId) {
        caseId = currentCaseId++;
        Case storage currentCase = cases[caseId];
        currentCase.status = CaseStatus.CREATED;
        currentCase.rulingContract = rulingContract;
        currentCase.totalContextProvidersWaiting = participants.length;
        // solhint-disable-next-line not-rely-on-time
        currentCase.deadline = block.timestamp + MAX_DEADLINE;

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
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
        if (
            currentCase.contextProviders[_msgSender()] != ContextStatus.SELECTED
        ) {
            revert ContextProviderNotSelected(caseId, _msgSender());
        }
        currentCase.contextProviders[_msgSender()] = ContextStatus
            .DROPPED_THE_MIC;
        currentCase.totalContextProvidersWaiting--;

        emit DroppedTheMic(caseId, _msgSender());
    }


    function executeRuling(uint256 caseId) external {
        // CHECKS
        Case storage currentCase = cases[caseId];
        if (currentCase.status != CaseStatus.READY_TO_EXECUTE) {
            revert CaseInWrongStatus(caseId, CaseStatus.READY_TO_EXECUTE);
        }
        // EFFECTS
        uint256 rulingResult = abi.decode(currentCase.response, (uint256));
        currentCase.status = CaseStatus.EXECUTED;

        // INTERACTIONS
        currentCase.rulingContract.rule(caseId, rulingResult);

        emit CaseRuled(caseId, rulingResult);
    }

    function isCaseReadyToExecute(uint256 caseId) public view returns (bool) {
        Case storage currentCase = cases[caseId];
        return
            // solhint-disable-next-line not-rely-on-time
            (block.timestamp > currentCase.deadline ||
                currentCase.totalContextProvidersWaiting == 0) &&
            currentCase.status == CaseStatus.CREATED;
    }
}
