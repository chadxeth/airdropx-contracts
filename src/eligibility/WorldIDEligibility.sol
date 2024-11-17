// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ICriteriaLogic.sol";
import { ByteHasher } from '../helpers/ByteHasher.sol';
import { IWorldID } from '../interfaces/IWorldID.sol';
import "forge-std/console.sol";

contract WorldIDEligibility is ICriteriaLogic {
    using ByteHasher for bytes;

    error DuplicateNullifier(uint256 nullifierHash);
    error NotVerified(address user);

    IWorldID internal immutable worldId;
    uint256 internal immutable externalNullifier;
    uint256 internal immutable groupId = 1;

    // Track verified users and their nullifier hashes
    mapping(uint256 => bool) internal nullifierHashes;
    mapping(address => bool) public isVerified;

    // Reward amount for verified humans
    uint256 constant REWARD_AMOUNT = 100 ether; // 100 tokens

    event Verified(address indexed user, uint256 nullifierHash);

    constructor(
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId
    ) {
        worldId = _worldId;
        externalNullifier = abi.encodePacked(
            abi.encodePacked(_appId).hashToField(),
            _actionId
        ).hashToField();
    }

    function verifyUser(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external {
        // Check for duplicate nullifier
        if (nullifierHashes[nullifierHash]) revert DuplicateNullifier(nullifierHash);

        // Verify the proof using WorldID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        // Mark nullifier as used
        nullifierHashes[nullifierHash] = true;
        
        // Mark user as verified
        isVerified[signal] = true;

        emit Verified(signal, nullifierHash);
    }

    function calculateReward(address user) external view override returns (uint256) {
        if (!isVerified[user]) {
            return 0;
        }
        return REWARD_AMOUNT;
    }

    function recordInteraction(address user) external {
        
    }
}