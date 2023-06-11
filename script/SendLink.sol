// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/* solhint-disable no-global-import */
import "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import "../src/ModeratioWithConsumer.sol";

/* solhint-enable no-global-import */

contract SendLinkScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address moderatio = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);
        IERC20 linkToken = IERC20(address(0x326C977E6efc84E512bB9C30f76E30c160eD06FB));

        uint256 amount = 1 * 10 ** 18;
        linkToken.transfer(address(moderatio), amount);

        vm.stopBroadcast();
        console.log("link sent to %s", address(moderatio));
    }
}
