// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IRuler} from "./IRuler.sol";

interface IModeratioConsumer {
    // Create case for moderation
    // returns case id
    function createCase(
        address[] memory participants,
        IRuler rulingContract
    ) external returns (uint256);


}
