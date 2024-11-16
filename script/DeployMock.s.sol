// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockERC20} from "../src/mocks/MockERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMockScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock Token first
        MockERC20 mockToken = new MockERC20();
        console.log("MockERC20 deployed at:", address(mockToken));

        vm.stopBroadcast();
    }
}