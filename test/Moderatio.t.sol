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

    function testCreateCase() public {
        MockRuler ruler = new MockRuler();
        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit NewCase(0, address(ruler));
        // The event we get
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        uint256 caseId = moderatio.createCase(participants, ruler);

        (Moderatio.CaseStatus status, IRuler iruler, , , , , ) = moderatio
            .cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 0);
        assertEq(uint256(status), uint256(Moderatio.CaseStatus.CREATED));
    }

    function testFailSetSubscriptionIdAsNotOwner() public {
        vm.prank(address(0));
        moderatio.setSubscriptionId(10);
    }

    function testRevertWhenSetGasLimitAsNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0));
        moderatio.setGasLimit(10);
    }
}
