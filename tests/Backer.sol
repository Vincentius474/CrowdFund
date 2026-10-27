// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

// Test helper for Campaign_test.sol. It lives in its own file because Remix treats every
// contract inside a *_test.sol file as a test suite, and test methods cannot take parameters.
import "../contracts/Campaign.sol";

// A second participant, played by a contract, so a test can act as someone other than the creator.
contract Backer {
    function contributeTo(Campaign c) external payable {
        c.contribute{value: msg.value}();
    }

    function withdrawFrom(Campaign c) external {
        c.withdraw();
    }

    receive() external payable {}
}
