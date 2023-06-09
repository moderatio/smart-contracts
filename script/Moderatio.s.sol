
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/* solhint-disable no-global-import */
import "forge-std/Script.sol";
import "../src/Moderatio.sol";

/* solhint-enable no-global-import */

contract DeployModeratio is Script {

    function setUp() public {} 

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        uint64 subscriptionId = 1;
        uint32 gasLimit = 300000;
        vm.startBroadcast(deployerPrivateKey);

        Moderatio moderatio = new Moderatio(oracleAddress, subscriptionId, gasLimit);

        vm.stopBroadcast();
        console.log("Moderatio address: %s", address(moderatio));
    }
}
