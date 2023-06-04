// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Functions, FunctionsClient} from "@chainlink/v0.8/functions/dev/0_0_0/FunctionsClient.sol";

contract Moderatio is FunctionsClient {
    using Functions for Functions.Request;

    uint64 subscriptionId = 1;
    uint32 gasLimit = 1;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;
    uint256 public responseCounter;

    constructor(address oracle) FunctionsClient(oracle) {}

    function request(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args
    ) public returns (bytes32 requestId) {
        Functions.Request memory req;
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            source
        );
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
        if (args.length > 0) req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        latestRequestId = assignedReqID;
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
}
