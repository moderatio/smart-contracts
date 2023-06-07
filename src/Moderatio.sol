// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Functions, FunctionsClient} from "@chainlink/v0.8/functions/dev/0_0_0/FunctionsClient.sol";
import {IModeratio} from "./IModeratio.sol";
import {IRuler} from "./IRuler.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

contract Moderatio is FunctionsClient, IModeratio {
    using Functions for Functions.Request;

    uint256 public currentCaseId = 0;
    mapping(uint256 => Case) public cases;

    struct Case {
        IRuler rulingContract;
        bytes32 requestId;
    }

    uint64 public subscriptionId = 1;
    uint32 public gasLimit = 1;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;
    uint256 public responseCounter;

    event NewCase(uint256 indexed caseId, address rulingContract);

    error CaseArgsLengthError();

    constructor(address oracle) FunctionsClient(oracle) {}

    Functions.Request private req;

    // I need to check, I don't know if this works
    function setRequest(string calldata source, bytes calldata secrets) public view {
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            source
        );
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
    }

    function request(uint256 caseId) private returns (bytes32 requestId) {
        Case storage currentCase = cases[caseId];
        require(
            currentCase.requestId == 0 &&
                address(currentCase.rulingContract) != address(0)
            , "Case does not exist"
        );
        string[] memory args = new string[](1);
        args[0] = Strings.toString(caseId);
        req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        cases[caseId].requestId = assignedReqID;
        return assignedReqID;
    }

    function fulfillRequest(
        bytes32,
        bytes memory response,
        bytes memory err
    ) internal virtual override {
        latestResponse = response;
        latestError = err;
        responseCounter = responseCounter + 1;
    }

    function createCase(
        IRuler rulingContract
    ) external override returns (uint256 caseId) {
        caseId = currentCaseId++;
        cases[caseId].rulingContract = rulingContract;
    }

    function executeFuntion(uint256 caseId) external override {
        request(caseId);
    }
}
