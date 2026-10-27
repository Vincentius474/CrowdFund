// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

// !!! DELIBERATELY VULNERABLE: FOR THE LAB 2 REENTRANCY DEMONSTRATION ONLY. NEVER DEPLOY OR COPY. !!!
// refund() sends the ether BEFORE it zeroes the backer's balance (interaction before effect).
// Campaign.sol is the fixed version.

// Teaching example with a reentrancy bug.
contract VulnerableCampaign {
    uint256 public immutable goal;
    uint256 public immutable deadline;

    uint256 public totalRaised;
    mapping(address backer => uint256 amount) public contributions;

    error ZeroContribution();
    error CampaignEnded(uint256 deadline);
    error CampaignStillRunning(uint256 deadline);
    error GoalReached();
    error NothingToRefund();
    error TransferFailed();

    constructor(uint256 goal_, uint256 durationMinutes) {
        goal = goal_;
        deadline = block.timestamp + durationMinutes * 1 minutes;
    }

    function contribute() external payable {
        require(msg.value > 0, ZeroContribution());
        require(block.timestamp < deadline, CampaignEnded(deadline));
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function refund() external {
        require(block.timestamp >= deadline, CampaignStillRunning(deadline));
        require(totalRaised < goal, GoalReached());
        uint256 amount = contributions[msg.sender];
        require(amount > 0, NothingToRefund());
        // BUG: the ether is sent first ...
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, TransferFailed());
        // ... and the balance is zeroed only afterwards, so a receiver can call refund() again before this line runs.
        contributions[msg.sender] = 0;
    }
}
