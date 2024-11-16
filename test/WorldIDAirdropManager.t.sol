// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestHelper.sol";
import {IWorldID} from "../src/interfaces/IWorldID.sol";
import {WorldIDEligibility} from "../src/eligibility/WorldIDEligibility.sol";

contract MockWorldID is IWorldID {
    mapping(address => bool) public verified;
    
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external view override {
        revert("Mock should be called via try/catch"); 
    }
}

contract WorldIDAirdropManagerTest is TestHelper {
    WorldIDEligibility public worldIDEligibility;
    MockWorldID public mockWorldID;
    uint256 public campaignId;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy mock WorldID
        mockWorldID = new MockWorldID();
        
        // Deploy WorldIDEligibility
        worldIDEligibility = new WorldIDEligibility(
            IWorldID(address(mockWorldID)),
            "test_app",
            "test_action"
        );
        
        // Create campaign with WorldIDEligibility
        vm.startPrank(alice);
        campaignId = airdropManager.createCampaign(
            address(rewardToken),
            1000 ether,
            100,
            block.timestamp,
            block.timestamp + 1 days,
            address(worldIDEligibility)
        );
        vm.stopPrank();
    }

    function testVerifyAndClaim() public {
        vm.startPrank(bob);
        
        // Create mock proof data
        uint256[8] memory proof;
        proof[0] = 1; // Mock proof data
        
        // Verify with WorldID
        worldIDEligibility.verifyUser(
            bob,
            123, // root
            456, // nullifierHash
            proof
        );
        
        // Check if verified
        assertTrue(worldIDEligibility.isVerified(bob), "User should be verified");
        
        // Claim reward
        uint256 balanceBefore = rewardToken.balanceOf(bob);
        airdropManager.claimReward(campaignId);
        
        // Verify reward amount
        assertEq(
            rewardToken.balanceOf(bob) - balanceBefore,
            100 ether,
            "Incorrect reward amount"
        );
        
        vm.stopPrank();
    }

    function testClaimWithoutVerification() public {
        vm.startPrank(bob);
        
        // Try to claim without verification
        vm.expectRevert(); // Should revert as user is not verified
        airdropManager.claimReward(campaignId);
        
        vm.stopPrank();
    }

    function testDuplicateVerification() public {
        vm.startPrank(bob);
        
        // First verification
        uint256[8] memory proof;
        worldIDEligibility.verifyUser(bob, 123, 456, proof);
        
        // Try to verify again with same nullifier
        vm.expectRevert(WorldIDEligibility.DuplicateNullifier.selector);
        worldIDEligibility.verifyUser(bob, 123, 456, proof);
        
        vm.stopPrank();
    }

    function testMultipleUsersClaim() public {
        // Verify and claim for Bob
        vm.startPrank(bob);
        uint256[8] memory proofBob;
        worldIDEligibility.verifyUser(bob, 123, 456, proofBob);
        uint256 bobBalanceBefore = rewardToken.balanceOf(bob);
        airdropManager.claimReward(campaignId);
        assertEq(
            rewardToken.balanceOf(bob) - bobBalanceBefore,
            100 ether,
            "Incorrect reward for Bob"
        );
        vm.stopPrank();

        // Verify and claim for Carol
        vm.startPrank(carol);
        uint256[8] memory proofCarol;
        worldIDEligibility.verifyUser(carol, 789, 101, proofCarol);
        uint256 carolBalanceBefore = rewardToken.balanceOf(carol);
        airdropManager.claimReward(campaignId);
        assertEq(
            rewardToken.balanceOf(carol) - carolBalanceBefore,
            100 ether,
            "Incorrect reward for Carol"
        );
        vm.stopPrank();
    }
}