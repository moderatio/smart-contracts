// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@chainlink/v0.8/functions/dev/0_0_0/FunctionsClient.sol";

contract Moderatio is FunctionsClient {

  constructor(address oracle) FunctionsClient(oracle) {

  }

  function fulfillRequest(
      bytes32 requestId,
      bytes memory response,
      bytes memory err
  ) internal virtual override {}
}
