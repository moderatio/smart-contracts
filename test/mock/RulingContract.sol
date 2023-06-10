// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IRuler} from "../../src/IRuler.sol";
import "forge-std/Test.sol";

contract MockRuler is IRuler {
    function rule(uint256 caseId, uint256 result) external view override {
        console.log("Case ruled: ", caseId, "Result: ", result);
    }
}
