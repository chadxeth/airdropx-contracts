// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TestProtocol} from "../src/TestProtocol.sol";
import {AirdropManager} from "../src/AirdropManager.sol";
import {LiquidityBasedEligibility} from "../src/eligibility/LiquidityBasedEligbility.sol";
import {VLayerEligibility} from "../src/eligibility/VLayerEligibility.sol";
import {AverageBalance} from "../src/vlayer/AverageBalance.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {VennFirewallConsumer} from "onchain-firewall/packages/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol";
import "forge-std/console.sol";

contract DeployScript is Script {
    // Test tokens for the protocol
    address constant USDC = 0x5dEaC602762362FE5f135FA5904351916053cF70; // OP Sepolia USDC
    address constant WETH = 0x4200000000000000000000000000000000000006; // OP Sepolia WETH
    
    // VLayer parameters
    uint256 constant START_BLOCK = 17878662;
    uint256 constant END_BLOCK = 17988620;
    uint256 constant STEP = 9000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address firewallAddress = 0x04f3B196E30e6F78174EF95a612E1f85A3B4110C;
        // 1. Deploy Firewall first
        VennFirewallConsumer firewall = new VennFirewallConsumer();
        console.log("VennFirewallConsumer deployed at:", address(firewall));
        firewall.setFirewall(firewallAddress);
        firewall.setAttestationCenterProxy(firewallAddress);
        // 2. Deploy LiquidityBasedEligibility
        LiquidityBasedEligibility liquidityEligibility = new LiquidityBasedEligibility();
        
        // 3. Deploy TestProtocol
        TestProtocol protocol = new TestProtocol(USDC, WETH, address(liquidityEligibility));
        console.log("TestProtocol deployed at:", address(protocol));

        // 4. Deploy AirdropManager with Firewall
        AirdropManager airdropManager = new AirdropManager();
        airdropManager.setFirewall(firewallAddress);
        airdropManager.setAttestationCenterProxy(firewallAddress);
        console.log("AirdropManager deployed at:", address(airdropManager));

        console.log("LiquidityBasedEligibility deployed at:", address(liquidityEligibility));

        // 5. Deploy VLayer contracts
        AverageBalance averageBalanceProver = new AverageBalance(
            IERC20(USDC),
            START_BLOCK,
            END_BLOCK,
            STEP
        );
        console.log("AverageBalance prover deployed at:", address(averageBalanceProver));

        // 6. Deploy VLayerEligibility
        VLayerEligibility vlayerEligibility = new VLayerEligibility(
            address(protocol),
            address(averageBalanceProver),
            IERC20(USDC)
        );
        console.log("VLayerEligibility deployed at:", address(vlayerEligibility));

        vm.stopBroadcast();
    }
}