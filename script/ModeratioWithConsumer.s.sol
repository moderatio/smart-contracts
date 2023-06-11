// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/* solhint-disable no-global-import */
import "forge-std/Script.sol";
import "../src/ModeratioWithConsumer.sol";

/* solhint-enable no-global-import */

contract DeployModeratioWithConsumer is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint32 gasLimit = 300000;
        vm.startBroadcast(deployerPrivateKey);

        ModeratioWithConsumer moderatio = new ModeratioWithConsumer(
        0x40193c8518BB267228Fc409a613bDbD8eC5a97b3,
         "ca98366cc7314957b8c012c72f05aeeb",
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        );

        vm.stopBroadcast();
        console.log("Moderatio address: %s", address(moderatio));
    }
}
