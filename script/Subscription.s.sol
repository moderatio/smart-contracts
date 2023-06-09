// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/* solhint-disable no-global-import */
import "forge-std/Script.sol";
import {FunctionsBillingRegistry} from "@chainlink/v0.8/functions/dev/0_0_0/FunctionsBillingRegistry.sol";
import {FunctionsOracle} from "@chainlink/v0.8/functions/dev/0_0_0/FunctionsOracle.sol";

/* solhint-enable no-global-import */

contract SubscriptionCreate is Script {
    // we test this script by running it in the VM
    function setUp() public {
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        FunctionsOracle oracle = FunctionsOracle(oracleAddress);
        address[] memory authorizedSenders = new address[](1);
        authorizedSenders[0] = 0xC4997A3eD87A40d5789a34396A2141465A4c414a;
        // owner of contract
        vm.broadcast(0x9ED925d8206a4f88a2f643b28B3035B315753Cd6);
        oracle.addAuthorizedSenders(authorizedSenders);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address billingRegistryAddress = vm.envAddress(
            "BILLING_REGISTRY_ADDRESS"
        );
        vm.startBroadcast(deployerPrivateKey);
        FunctionsBillingRegistry registry = FunctionsBillingRegistry(
            billingRegistryAddress
        );
        uint64 subscriptionId = registry.createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID: %s", subscriptionId);
    }
}

contract SubscriptionFund is Script {
    // we test this script by running it in the VM
    function setUp() public {}

    function run() public {}
}
