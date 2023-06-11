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

    event NewCase(uint256 indexed caseId, address rulingContract);

    function setUp() public {
        linkToken = new LinkToken();
        mockOracle = new MockOracle(address(linkToken));
        moderatio = new ModeratioWithConsumer(address(mockOracle), jobId, address(linkToken));
        ruler = new MockRuler();
    }

    function testCreateCase() public {
        vm.expectEmit(true, false, false, true);
        // The event we expect
        emit NewCase(0, address(ruler));
        // The event we get
        address[] memory participants = new address[](2);
        participants[0] = address(0x1);
        participants[1] = address(0x2);
        caseId = moderatio.createCase(participants, ruler);

        (ModeratioWithConsumer.CaseStatus status, IRuler iruler,,,,,) = moderatio.cases(caseId);
        assertEq(address(ruler), address(iruler));
        assertEq(caseId, 0);
        assertEq(uint256(status), uint256(ModeratioWithConsumer.CaseStatus.CREATED));

        assertEq(caseId, 0);
        vm.prank(address(0x1));
        moderatio.dropTheMic(0);
    }

    function testDropTheMic() public {
        // console.log(caseId);
        // (ModeratioWithConsumer.CaseStatus status, IRuler iruler,,,,,) = moderatio.cases(caseId);
        // assertEq(address(ruler), address(iruler));
        // assertEq(caseId, 0);
        // vm.prank(address(0x1));
        // moderatio.dropTheMic(0);
    }
}
