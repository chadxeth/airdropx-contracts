// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICriteriaLogic {
    function calculateReward(address user) external view returns (uint256);
}
