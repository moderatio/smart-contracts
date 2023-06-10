pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/ModeratioWithConsumer.sol";
import {MockRuler} from "./mock/RulingContract.sol";
import {IRuler} from "../src/IRuler.sol";

contract ModeratioWithConsumerTest is Test {
    ModeratioWithConsumer public moderatio;

    event NewCase(uint256 indexed caseId, address rulingContract);

    function setUp() public {
        moderatio = new ModeratioWithConsumer();
    }

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

        (ModeratioWithConsumer.CaseStatus status, IRuler iruler,,,,,) = moderatio.cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 0);
        assertEq(uint256(status), uint256(ModeratioWithConsumer.CaseStatus.CREATED));
    }
}
