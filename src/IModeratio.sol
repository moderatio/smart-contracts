// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRuler} from "./IRuler.sol";

interface IModeratio {
    // Create case for moderation
    // returns case id
    function createCase(IRuler rulingContract) external returns (uint256);

    function executeFunction(
        uint256 caseId,
        string calldata source,
        bytes calldata secrets
    ) external;
}
