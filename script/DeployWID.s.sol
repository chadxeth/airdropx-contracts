// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {WorldIDEligibility} from "../src/eligibility/WorldIDEligibility.sol";
import {IWorldID} from "../src/interfaces/IWorldID.sol";
import "forge-std/console.sol";

contract DeployWorldIDScript is Script {
    // WorldID contract address on Base Sepolia
    address constant WORLD_ID_ADDRESS = 0x11cA3127182f7583EfC416a8771BD4d11Fae4334;
    
    // App-specific parameters
    string constant APP_ID = "airdropx";
    string constant ACTION_ID = "claim";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WorldIDEligibility
        WorldIDEligibility worldIDEligibility = new WorldIDEligibility(
            IWorldID(WORLD_ID_ADDRESS),
            APP_ID,
            ACTION_ID
        );
        
        console.log("WorldIDEligibility deployed at:", address(worldIDEligibility));

        vm.stopBroadcast();
    }
}