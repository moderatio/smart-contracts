pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/ModeratioWithConsumer.sol";
import {MockRuler} from "./mock/RulingContract.sol";
import {IRuler} from "../src/IRuler.sol";
import {LinkToken} from "./mock/LinkToken.sol";
import {MockOracle} from "./mock/MockOracle.sol";

contract ModeratioWithConsumerTest is Test {
    ModeratioWithConsumer public moderatio;
    LinkToken public linkToken;
    MockOracle public mockOracle;
    MockRuler ruler;
    bytes32 jobId;
    uint256 caseId;
    bytes32 blank_bytes32;

    uint256 constant RESPONSE = 1;

    error ContextProviderNotSelected(uint256 caseId, address provider);

    event NewCase(uint256 indexed caseId, address rulingContract);
    event DroppedTheMic(uint256 indexed caseId, address contextProvider);

    function setUp() public {
        linkToken = new LinkToken();
        mockOracle = new MockOracle(address(linkToken));
        moderatio = new ModeratioWithConsumer(address(mockOracle), jobId, address(linkToken));
        ruler = new MockRuler();
        uint256 amount = 1 * 10 ** 18;
        linkToken.transfer(address(moderatio), amount);
    }

    function testCreateCase() public {
        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit NewCase(1, address(ruler));
        // The event we get
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        (ModeratioWithConsumer.CaseStatus status, IRuler iruler,,,,,) = moderatio.cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 1);
        assertEq(uint256(status), uint256(ModeratioWithConsumer.CaseStatus.CREATED));

        assertEq(caseId, 1);
        vm.prank(address(0x1));
        moderatio.dropTheMic(1);
    }

    function test_RevertIf_duplicateParticipant() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x1);
        vm.expectRevert();
        caseId = moderatio.createCase(participants, ruler);
    }

    function testDropTheMic() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        // console.log(caseId);
        vm.prank(address(0x1));

        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit DroppedTheMic(1, address(0x1));
        moderatio.dropTheMic(1);
    }

    function testDropTheMicSingleProvider() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        caseId = moderatio.createCase(participants, ruler);

        // console.log(caseId);
        vm.prank(address(0x1));

        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit DroppedTheMic(1, address(0x1));
        moderatio.dropTheMic(1);
    }

    function test_RevertIf_ContextProviderNotSelected() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        vm.prank(address(0x3));

        vm.expectRevert(abi.encodeWithSelector(ContextProviderNotSelected.selector, 1, address(0x3)));
        moderatio.dropTheMic(1);
    }

    function testRequest() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        // console.log(caseId);
        vm.prank(address(0x1));
        // The event we expect
        moderatio.dropTheMic(1);
        vm.prank(address(0x2));
        moderatio.dropTheMic(1);

        bytes32 requestId = moderatio.request(caseId);
        assertTrue(requestId != blank_bytes32);
    }

    function testGetCaseParticipantsStatus() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        ModeratioWithConsumer.ContextStatus status = moderatio.getCaseContextProviderStatus(caseId, address(0x1));
        assertTrue(status == ModeratioWithConsumer.ContextStatus.SELECTED);

        vm.prank(address(0x1));
        moderatio.dropTheMic(1);

        status = moderatio.getCaseContextProviderStatus(caseId, address(0x1));
        assertTrue(status == ModeratioWithConsumer.ContextStatus.DROPPED_THE_MIC);
    }

    function testRequestFulfill() public {
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        // console.log(caseId);
        vm.prank(address(0x1));
        // The event we expect
        moderatio.dropTheMic(1);
        vm.prank(address(0x2));
        moderatio.dropTheMic(1);

        bytes32 requestId = moderatio.request(caseId);

        mockOracle.fulfillOracleRequest(requestId, bytes32(RESPONSE));

        moderatio.executeRuling(caseId);
    }
}
