// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Functions, FunctionsClient} from "@chainlink/v0.8/functions/dev/0_0_0/FunctionsClient.sol";
import {IModeratio} from "./IModeratio.sol";
import {IRuler} from "./IRuler.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract Moderatio is FunctionsClient, IModeratio, Ownable {
    using Functions for Functions.Request;

    uint256 public currentCaseId = 0;
    mapping(uint256 => Case) public cases;
    mapping(bytes32 => uint256) public requestIdToCaseId;

    struct Case {
        IRuler rulingContract;
        // chainlink functions
        bytes32 requestId;
        bytes response;
        bytes error;

        bool executed;
    }

    uint64 public subscriptionId = 1;
    uint32 public gasLimit = 1;

    event NewCase(uint256 indexed caseId, address rulingContract);
    event CaseRuled(uint256 indexed caseId, uint256 result);

    error CaseArgsLengthError();
    error CaseDoesNotHaveResponse();
    error CaseAlreadyExecuted();

    constructor(address oracle) FunctionsClient(oracle) {}

    Functions.Request private req;

    // I need to check, I don't know if this works
    function setRequest(
        string calldata source,
        bytes calldata secrets
    ) public view onlyOwner {
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            source
        );
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
    }

    function _request(uint256 caseId) private returns (bytes32 requestId) {
        Case storage currentCase = cases[caseId];
        require(
            currentCase.requestId == 0 &&
                address(currentCase.rulingContract) != address(0),
            "Case does not exist"
        );
        string[] memory args = new string[](1);
        args[0] = Strings.toString(caseId);
        req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        cases[caseId].requestId = assignedReqID;
        requestIdToCaseId[assignedReqID] = caseId;
        return assignedReqID;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal virtual override {
        uint256 caseId = requestIdToCaseId[requestId];
        Case storage currentCase = cases[caseId];

        currentCase.response = response;
        currentCase.error = err;
    }

    function createCase(
        IRuler rulingContract
    ) external override returns (uint256 caseId) {
        caseId = currentCaseId++;
        cases[caseId].rulingContract = rulingContract;
    }

    function executeFunction(uint256 caseId) external override {
        _request(caseId);
    }

    function executeRuling(uint256 caseId) external {
        // CHECKS
        Case storage currentCase = cases[caseId];
        if (currentCase.response.length == 0) {
            revert CaseDoesNotHaveResponse();
        }
        if (currentCase.executed) {
            revert CaseAlreadyExecuted();
        }
        // EFFECTS
        uint256 rulingResult = abi.decode(currentCase.response, (uint256));
        currentCase.executed = true;

        // INTERACTIONS
        currentCase.rulingContract.rule(caseId, rulingResult);

        emit CaseRuled(caseId, rulingResult);
    }
}
