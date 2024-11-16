// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestHelper.sol";

contract AirdropManagerTest is TestHelper {
    uint256 public campaignId;
    
    function setUp() public override {
        super.setUp();
        
        vm.startPrank(alice);
        campaignId = airdropManager.createCampaign(
            address(rewardToken),
            1000 ether,
            100,
            block.timestamp,
            block.timestamp + 1 days,
            address(liquidityEligibility)
        );
        vm.stopPrank();
    }

    function testCreateCampaignInvalidDuration() public {
        vm.startPrank(alice);
        vm.expectRevert("Invalid campaign duration");
        airdropManager.createCampaign(
            address(rewardToken),
            1000 ether,
            100,
            block.timestamp + 1 days, // Start time after end time
            block.timestamp,
            address(liquidityEligibility)
        );
        vm.stopPrank();
    }

    function testCreateCampaignInsufficientAllowance() public {
        vm.startPrank(alice);
        rewardToken.approve(address(airdropManager), 0); // Reset allowance
        
        vm.expectRevert();
        airdropManager.createCampaign(
            address(rewardToken),
            1000 ether,
            100,
            block.timestamp,
            block.timestamp + 1 days,
            address(liquidityEligibility)
        );
        vm.stopPrank();
    }

    // Test claim reward
    function testClaimReward() public {
        // Simulate eligible user
        vm.startPrank(bob);
        
        uint256 balanceBefore = rewardToken.balanceOf(bob);
        // Add liquidity
        protocol.addLiquidity(100 ether, 100 ether);
        // Claim reward
        airdropManager.claimReward(campaignId);
        
        // Verify reward amount
        uint256 expectedReward = 100 ether; // 1000 ether / 100 participants
        assertEq(
            rewardToken.balanceOf(bob) - balanceBefore,
            expectedReward,
            "Incorrect reward amount"
        );
        
        // Try to claim again
        vm.expectRevert("Already claimed");
        airdropManager.claimReward(campaignId);
        vm.stopPrank();
    }

    function testClaimRewardBeforeStart() public {
        // Create campaign with future start time
        vm.startPrank(alice);
        uint256 futureId = airdropManager.createCampaign(
            address(rewardToken),
            1000 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            address(liquidityEligibility)
        );
        vm.stopPrank();

        vm.expectRevert("Campaign not started");
        airdropManager.claimReward(futureId);
    }

    function testClaimRewardAfterEnd() public {
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("Campaign ended");
        airdropManager.claimReward(campaignId);
    }

    function testWithdrawUnusedRewardsBeforeEnd() public {
        vm.startPrank(alice);
        vm.expectRevert("Campaign still active");
        airdropManager.withdrawUnusedRewards(campaignId);
        vm.stopPrank();
    }

    function testWithdrawUnusedRewardsNonCreator() public {
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(bob);
        vm.expectRevert("Not creator");
        airdropManager.withdrawUnusedRewards(campaignId);
        vm.stopPrank();
    }
}