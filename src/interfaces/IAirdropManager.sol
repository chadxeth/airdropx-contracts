// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAirdropManager {
    struct Campaign {
        address creator;
        address rewardToken;
        uint256 totalRewards;
        uint256 maxParticipants;
        uint256 startTime;
        uint256 endTime;
        bool active;
        address criteriaLogic;
    }

    event CampaignCreated(uint256 campaignId, address indexed creator);
    event RewardClaimed(uint256 campaignId, address indexed user, uint256 amount);

    function createCampaign(
        address rewardToken,
        uint256 totalRewards,
        uint256 maxParticipants,
        uint256 startTime,
        uint256 endTime,
        address criteriaLogic
    ) external returns (uint256);

    function claimReward(uint256 campaignId) external;

    function getCampaign(uint256 campaignId) external view returns (Campaign memory);

    function withdrawUnusedRewards(uint256 campaignId) external;
}
