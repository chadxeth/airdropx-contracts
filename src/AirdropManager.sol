// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IAirdropManager.sol";
import "./interfaces/ICriteriaLogic.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract AirdropManager is IAirdropManager {
    uint256 private campaignCounter;
    mapping(uint256 => Campaign) private campaigns;
    mapping(uint256 => mapping(address => bool)) private hasClaimed;

    function createCampaign(
        address rewardToken,
        uint256 totalRewards,
        uint256 maxParticipants,
        uint256 startTime,
        uint256 endTime,
        address criteriaLogic
    ) external override returns (uint256) {
        require(endTime > startTime, "Invalid campaign duration");

        IERC20(rewardToken).transferFrom(msg.sender, address(this), totalRewards);

        campaignCounter++;
        campaigns[campaignCounter] = Campaign({
            creator: msg.sender,
            rewardToken: rewardToken,
            totalRewards: totalRewards,
            maxParticipants: maxParticipants,
            startTime: startTime,
            endTime: endTime,
            active: true,
            criteriaLogic: criteriaLogic
        });

        emit CampaignCreated(campaignCounter, msg.sender);
        return campaignCounter;
    }

    function claimReward(uint256 campaignId) external override {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.startTime, "Campaign not started");
        require(block.timestamp <= campaign.endTime, "Campaign ended");
        require(campaign.active, "Campaign inactive");
        require(!hasClaimed[campaignId][msg.sender], "Already claimed");

        ICriteriaLogic criteria = ICriteriaLogic(campaign.criteriaLogic);
        uint256 reward = criteria.calculateReward(msg.sender);

        hasClaimed[campaignId][msg.sender] = true;
        IERC20(campaign.rewardToken).transfer(msg.sender, reward);

        emit RewardClaimed(campaignId, msg.sender, reward);
    }

    function getCampaign(uint256 campaignId) external view override returns (Campaign memory) {
        return campaigns[campaignId];
    }

    function withdrawUnusedRewards(uint256 campaignId) external override {
        Campaign storage campaign = campaigns[campaignId];
        require(msg.sender == campaign.creator, "Not creator");
        require(block.timestamp > campaign.endTime, "Campaign still active");

        uint256 remainingRewards = IERC20(campaign.rewardToken).balanceOf(address(this));
        IERC20(campaign.rewardToken).transfer(campaign.creator, remainingRewards);
        campaign.active = false;
    }
}
