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

    event NewCase(uint256 indexed caseId, address rulingContract);

    function test_CreateCase() public {
        MockRuler ruler = new MockRuler();
        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit NewCase(0, address(ruler));
        // The event we get
        uint256 caseId = moderatio.createCase(ruler);

        (IRuler iruler, , , , ) = moderatio.cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 0);
    }

    function testFail_SetSubscriptionIdAsNotOwner() public {
        vm.prank(address(0));
        moderatio.setSubscriptionId(10);
    }


    function test_RevertWhen_SetGasLimitAsNotOwner() public {
        vm.expectRevert( "Ownable: caller is not the owner");
        vm.prank(address(0));
        moderatio.setGasLimit(10);
    }
}
