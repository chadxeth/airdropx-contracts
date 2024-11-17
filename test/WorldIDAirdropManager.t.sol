// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestHelper.sol";
import {WorldIDEligibility} from "../src/eligibility/WorldIDEligibility.sol";
import {IWorldID} from "../src/interfaces/IWorldID.sol";

contract MockWorldID is IWorldID {
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external pure override {
        // Mock implementation that accepts any proof
    }
}

contract WorldIDAirdropManagerTest is TestHelper {
    uint256 public campaignId;
    WorldIDEligibility public worldIDEligibility;
    MockWorldID public mockWorldID;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy mock WorldID and WorldIDEligibility
        mockWorldID = new MockWorldID();
        worldIDEligibility = new WorldIDEligibility(
            IWorldID(address(mockWorldID)),
            "airdropx",
            "claim"
        );
        
        // Create campaign with WorldID eligibility
        vm.startPrank(alice);
        campaignId = airdropManager.createCampaign(
            address(rewardToken),
            10000 ether,
            100,
            block.timestamp,
            block.timestamp + 1 days,
            address(worldIDEligibility)
        );
        vm.stopPrank();
    }

    function testVerifyAndClaim() public {
        vm.startPrank(bob);
        
        // Create mock verification data
        uint256[8] memory proof;
        uint256 root = 1;
        uint256 nullifierHash = 123;
        bytes memory signal = abi.encodePacked(bob);
        
        // Verify WorldID
        worldIDEligibility.verifyUser(
            bob,
            root,
            nullifierHash,
            proof
        );
        
        // Check balance before claim
        uint256 balanceBefore = rewardToken.balanceOf(bob);
        
        // Claim reward
        airdropManager.claimReward(campaignId);
        
        // Verify reward amount (100 tokens for verified humans)
        assertEq(
            rewardToken.balanceOf(bob) - balanceBefore,
            100 ether,
            "Incorrect reward amount"
        );
        
        vm.stopPrank();
    }

    function testCannotReuseNullifier() public {
        vm.startPrank(bob);
        
        uint256[8] memory proof;
        uint256 root = 1;
        uint256 nullifierHash = 123;
        bytes memory signal = abi.encodePacked(bob);
        
        // Verify WorldID
        worldIDEligibility.verifyUser(
            bob,
            root,
            nullifierHash,
            proof
        );
        
        // Try to verify again with same nullifier
        vm.expectRevert(abi.encodeWithSignature("DuplicateNullifier(uint256)", nullifierHash));
        // Verify WorldID
        worldIDEligibility.verifyUser(
            bob,
            root,
            nullifierHash,
            proof
        );
        
        vm.stopPrank();
    }

}