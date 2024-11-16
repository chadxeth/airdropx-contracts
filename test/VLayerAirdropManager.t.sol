// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestHelper.sol";
import {AverageBalance} from "../src/vlayer/AverageBalance.sol";
import {Proof, CallAssumptions, Seal} from "vlayer-0.1.0/Proof.sol";
import {ProofMode} from "vlayer-0.1.0/Seal.sol";

contract VLayerAirdropManagerTest is TestHelper {
    uint256 public campaignId;
    
    function setUp() public override {
        super.setUp();
        
        vm.startPrank(alice);
        campaignId = airdropManager.createCampaign(
            address(rewardToken),
            10000 ether,
            100,
            block.timestamp,
            block.timestamp + 1 days,
            address(vlayerEligibility)
        );
        vm.stopPrank();
    }

    function createMockProof() internal view returns (Proof memory) {
        // Create mock call assumptions
        CallAssumptions memory assumptions = CallAssumptions({
            proverContractAddress: address(averageBalance),
            functionSelector: averageBalance.averageBalanceOf.selector,
            settleBlockNumber: block.number - 1,
            settleBlockHash: blockhash(block.number - 1)
        });

        // Create mock seal
        bytes32[8] memory sealData;
        sealData[0] = bytes32(uint256(1)); // Mock seal data
        
        Seal memory seal = Seal({
            verifierSelector: bytes4(keccak256("mockVerifier()")),
            seal: sealData,
            mode: ProofMode.FAKE
        });

        return Proof({
            seal: seal,
            callGuestId: keccak256("mockGuest"),
            length: 32, // Mock length
            callAssumptions: assumptions
        });
    }

    function testSubmitProofAndClaim() public {
        // Submit proof for bob with 500 token average balance (Tier 2)
        vm.startPrank(bob);
        callProver();
        // Then call the actual prover function which will be intercepted
        (,, uint256 balance) = AverageBalance(averageBalance).averageBalanceOf(bob);
        
        // Get the proof from the previous call
        Proof memory proof = getProof();
        vlayerEligibility.submitProof(proof, bob, 500 ether);
        
        uint256 balanceBefore = rewardToken.balanceOf(bob);
        airdropManager.claimReward(campaignId);
        uint256 expectedReward = 300 ether;
        assertEq(
            rewardToken.balanceOf(bob) - balanceBefore,
            expectedReward,
            "Incorrect reward amount for Tier 2"
        );
        vm.stopPrank();
    }

    function testSubmitInvalidProof() public {
        // Create invalid proof with wrong block hash
        CallAssumptions memory invalidAssumptions = CallAssumptions({
            proverContractAddress: address(averageBalance),
            functionSelector: averageBalance.averageBalanceOf.selector,
            settleBlockNumber: block.number - 1,
            settleBlockHash: bytes32(0) // Invalid block hash
        });

        bytes32[8] memory sealData;
        Seal memory seal = Seal({
            verifierSelector: bytes4(keccak256("mockVerifier()")),
            seal: sealData,
            mode: ProofMode.FAKE
        });

        Proof memory invalidProof = Proof({
            seal: seal,
            callGuestId: bytes32(0), // Invalid guest ID
            length: 0,  // Invalid length
            callAssumptions: invalidAssumptions
        });

        vm.startPrank(bob);
        vm.expectRevert(); // Should revert with invalid proof
        vlayerEligibility.submitProof(invalidProof, bob, 100 ether);
        vm.stopPrank();
    }

    function testMultipleUsersClaimDifferentTiers() public {
        // Bob: Tier 1 (100 tokens average)
        vm.startPrank(bob);
        callProver();
        // Then call the actual prover function which will be intercepted
        (,, uint256 balance) = AverageBalance(averageBalance).averageBalanceOf(bob);
        // Get the proof from the previous call
        Proof memory proof = getProof();
        vlayerEligibility.submitProof(proof, bob, 100 ether);
        uint256 bobBalanceBefore = rewardToken.balanceOf(bob);
        airdropManager.claimReward(campaignId);
        assertEq(
            rewardToken.balanceOf(bob) - bobBalanceBefore,
            100 ether,
            "Incorrect Tier 1 reward"
        );
        vm.stopPrank();
        // Carol: Tier 3 (1000 tokens average)
        vm.startPrank(carol);
        callProver();
    
    // Then call the actual prover function which will be intercepted
        (,, uint256 balance2) = AverageBalance(averageBalance).averageBalanceOf(bob);
        
        // Get the proof from the previous call
        Proof memory proof2 = getProof();
        vlayerEligibility.submitProof(proof2, carol, 1000 ether);
        uint256 carolBalanceBefore = rewardToken.balanceOf(carol);
        airdropManager.claimReward(campaignId);
        assertEq(
            rewardToken.balanceOf(carol) - carolBalanceBefore,
            600 ether,
            "Incorrect Tier 3 reward"
        );
        vm.stopPrank();
    }
} 