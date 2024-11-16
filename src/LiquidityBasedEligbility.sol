// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ICriteriaLogic.sol";

contract LiquidityBasedEligibility is ICriteriaLogic {
    address public implementation;
    
    // Mapping to track historical liquidity additions
    mapping(address => uint256) public liquidityAdditions;
    
    // Reward tiers (number of interactions => reward amount)
    uint256 constant TIER1_THRESHOLD = 1;  // 100 tokens
    uint256 constant TIER2_THRESHOLD = 5;  // 300 tokens
    uint256 constant TIER3_THRESHOLD = 10; // 600 tokens
    uint256 constant TIER4_THRESHOLD = 20; // 1000 tokens
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    function calculateReward(address user) external view override returns (uint256) {
        uint256 interactions = liquidityAdditions[user];
        
        // No reward if no interactions
        if (interactions == 0) {
            return 0;
        }
        // Tier 1: 1-4 interactions
        else if (interactions >= TIER1_THRESHOLD && interactions < TIER2_THRESHOLD) {
            return 100 ether; // 100 tokens
        }
        // Tier 2: 5-9 interactions
        else if (interactions >= TIER2_THRESHOLD && interactions < TIER3_THRESHOLD) {
            return 300 ether; // 300 tokens
        }
        // Tier 3: 10-19 interactions
        else if (interactions >= TIER3_THRESHOLD && interactions < TIER4_THRESHOLD) {
            return 600 ether; // 600 tokens
        }
        // Tier 4: 20+ interactions
        else {
            return 1000 ether; // 1000 tokens
        }
    }

    fallback() external payable {
        // Forward call to ContractA
        (bool success, bytes memory result) = implementation.call{value: msg.value}(msg.data);
        // Require success
        require(success, "Call to implementation failed");
        // Increment liquidity additions
        liquidityAdditions[msg.sender] += 1;

        // Return the result back to the caller
        assembly {
            return(add(result, 0x20), mload(result))
        }
    }

    // Allow the proxy to receive Ether
    receive() external payable {}
    
}