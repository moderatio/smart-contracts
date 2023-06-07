// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* solhint-disable no-global-import */
import "forge-std/Test.sol";
import "../src/Moderatio.sol";
/* solhint-enable no-global-import */

import {MockRuler} from "./mock/RulingContract.sol";
import {IRuler} from "../src/IRuler.sol";

contract ModeratioTest is Test {
    Moderatio public moderatio;

    function setUp() public {
        address oracle = address(0);
        uint64 subscriptionId = 1;
        uint32 gasLimit = 300000;

        moderatio = new Moderatio(oracle, subscriptionId, gasLimit);
    }

    function testCreateCase() public {
        MockRuler ruler = new MockRuler();
        uint256 caseId = moderatio.createCase(ruler);

        (IRuler iruler, , , , ) = moderatio.cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 0);
    }
}
