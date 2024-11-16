// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ICriteriaLogic.sol";
import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract VLayerEligibility is ICriteriaLogic, Verifier {
    address public implementation;
    address public immutable averageBalanceProver;
    IERC20 public immutable token;
    
    // Average balance thresholds for reward tiers (in token decimals)
    uint256 constant TIER1_THRESHOLD = 100 ether;   // 100 tokens average
    uint256 constant TIER2_THRESHOLD = 500 ether;   // 500 tokens average
    uint256 constant TIER3_THRESHOLD = 1000 ether;  // 1000 tokens average
    uint256 constant TIER4_THRESHOLD = 5000 ether;  // 5000 tokens average
    
    // Mapping to store verified average balances
    mapping(address => uint256) public verifiedAverageBalances;
    
    constructor(
        address _implementation,
        address _averageBalanceProver,
        IERC20 _token
    ) {
        implementation = _implementation;
        averageBalanceProver = _averageBalanceProver;
        token = _token;
    }
    
    function submitProof(Proof calldata proof, address user, uint256 averageBalance) 
        external 
        onlyVerified(averageBalanceProver, bytes4(keccak256("averageBalanceOf(address)")))
    {
        verifiedAverageBalances[user] = averageBalance;
    }
    
    function calculateReward(address user) external view override returns (uint256) {
        uint256 avgBalance = verifiedAverageBalances[user];
        
        // No reward if no verified balance
        if (avgBalance == 0) {
            return 0;
        }
        // Tier 1: >= 100 tokens average
        else if (avgBalance >= TIER1_THRESHOLD && avgBalance < TIER2_THRESHOLD) {
            return 100 ether; // 100 reward tokens
        }
        // Tier 2: >= 500 tokens average
        else if (avgBalance >= TIER2_THRESHOLD && avgBalance < TIER3_THRESHOLD) {
            return 300 ether; // 300 reward tokens
        }
        // Tier 3: >= 1000 tokens average
        else if (avgBalance >= TIER3_THRESHOLD && avgBalance < TIER4_THRESHOLD) {
            return 600 ether; // 600 reward tokens
        }
        // Tier 4: >= 5000 tokens average
        else {
            return 1000 ether; // 1000 reward tokens
        }
    }

    function recordInteraction(address user) external {
        // No action needed for VLayerEligibility
    }
} 
