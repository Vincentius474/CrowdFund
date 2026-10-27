// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

// Run with Remix's Solidity Unit Testing plugin. Remix injects remix_tests.sol (the Assert library).
import "remix_tests.sol";
import "../contracts/Campaign.sol";
import "./Backer.sol";

// Unit tests for Campaign. The test contract deploys each Campaign, so it is the creator.
// These tests cover everything up to the deadline; the after-deadline paths are tried on Anvil (Lab 2 Step 6).
contract CampaignTest {
    Campaign campaign;
    Backer backer;

    function beforeAll() public {
        backer = new Backer();
    }

    // Fresh campaign for every test: 1 ether goal, 5 minutes.
    function beforeEach() public {
        campaign = new Campaign(1 ether, 5);
    }

    function checkConstructorSetsCreatorGoalAndDeadline() public {
        Assert.equal(campaign.creator(), address(this), "creator should be the deployer");
        Assert.equal(campaign.goal(), 1 ether, "goal should be 1 ether");
        Assert.equal(campaign.deadline(), block.timestamp + 5 minutes, "deadline should be 5 minutes ahead");
    }

    function checkZeroGoalIsRejected() public {
        try new Campaign(0, 5) returns (Campaign) {
            Assert.ok(false, "a zero goal should revert");
        } catch (bytes memory reason) {
            Assert.ok(bytes4(reason) == Campaign.InvalidGoal.selector, "expected InvalidGoal");
        }
    }

    /// #value: 300
    function checkContributionIsRecorded() public payable {
        campaign.contribute{value: msg.value}();
        Assert.equal(campaign.contributions(address(this)), 300, "contribution should be recorded");
        Assert.equal(campaign.totalRaised(), 300, "total raised should be 300 wei");
        Assert.equal(address(campaign).balance, 300, "the contract should hold the ether");
    }

    /// #value: 200
    function checkEachBackerIsTrackedSeparately() public payable {
        backer.contributeTo{value: msg.value}(campaign);
        Assert.equal(campaign.contributions(address(backer)), 200, "backer's contribution should be recorded");
        Assert.equal(campaign.contributions(address(this)), 0, "creator contributed nothing");
    }

    function checkZeroContributionReverts() public {
        try campaign.contribute{value: 0}() {
            Assert.ok(false, "a zero contribution should revert");
        } catch (bytes memory reason) {
            Assert.ok(bytes4(reason) == Campaign.ZeroContribution.selector, "expected ZeroContribution");
        }
    }

    function checkWithdrawBeforeDeadlineReverts() public {
        try campaign.withdraw() {
            Assert.ok(false, "withdraw before the deadline should revert");
        } catch (bytes memory reason) {
            Assert.ok(bytes4(reason) == Campaign.CampaignStillRunning.selector, "expected CampaignStillRunning");
        }
    }

    function checkOnlyCreatorCanWithdraw() public {
        try backer.withdrawFrom(campaign) {
            Assert.ok(false, "a non-creator withdraw should revert");
        } catch (bytes memory reason) {
            Assert.ok(bytes4(reason) == Campaign.NotCreator.selector, "expected NotCreator");
        }
    }

    function checkRefundBeforeDeadlineReverts() public {
        try campaign.refund() {
            Assert.ok(false, "refund before the deadline should revert");
        } catch (bytes memory reason) {
            Assert.ok(bytes4(reason) == Campaign.CampaignStillRunning.selector, "expected CampaignStillRunning");
        }
    }
}
