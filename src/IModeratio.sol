// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IModeratio {
  // Create case for moderation
  // returns case id
  function createCase() external returns (uint256);

  function rule(uint256 _caseId, uint256 _decision) external;

}
