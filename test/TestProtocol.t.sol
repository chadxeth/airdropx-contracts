// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestHelper.sol";

contract TestProtocolTest is TestHelper {
    function testAddLiquidityZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert();
        protocol.addLiquidity(0, 100 ether);
        vm.stopPrank();
    }

    function testAddLiquidityInsufficientAllowance() public {
        vm.startPrank(alice);
        token0.approve(address(protocol), 0);
        vm.expectRevert();
        protocol.addLiquidity(100 ether, 100 ether);
        vm.stopPrank();
    }

    function testAddLiquidityFirstProvider() public {
        vm.startPrank(alice);
        uint256 amount0 = 100 ether;
        uint256 amount1 = 200 ether;
        
        uint256 liquidityMinted = protocol.addLiquidity(amount0, amount1);
        assertEq(liquidityMinted, Math.sqrt(amount0 * amount1), "Incorrect initial liquidity");
        vm.stopPrank();
    }

    function testSwapInvalidToken() public {
        vm.startPrank(bob);
        address invalidToken = address(0x123);
        vm.expectRevert("Invalid token");
        protocol.swap(invalidToken, 10 ether);
        vm.stopPrank();
    }

    function testSwapZeroAmount() public {
        vm.startPrank(alice);
        protocol.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("Invalid amount");
        protocol.swap(address(token0), 0);
        vm.stopPrank();
    }

    function testRemoveLiquidityInsufficientBalance() public {
        vm.startPrank(alice);
        uint256 liquidityMinted = protocol.addLiquidity(100 ether, 100 ether);
        vm.expectRevert("Insufficient liquidity");
        protocol.removeLiquidity(liquidityMinted + 1);
        vm.stopPrank();
    }

    function testMultipleSwaps() public {
        // Add initial liquidity
        vm.startPrank(alice);
        protocol.addLiquidity(1000 ether, 1000 ether);
        vm.stopPrank();

        // Perform multiple swaps
        vm.startPrank(bob);
        for(uint i = 0; i < 3; i++) {
            uint256 amountOut = protocol.swap(address(token0), 10 ether);
            assertGt(amountOut, 0, "Swap should return tokens");
            
            // Swap back
            amountOut = protocol.swap(address(token1), 5 ether);
            assertGt(amountOut, 0, "Reverse swap should return tokens");
        }
        vm.stopPrank();
    }

    function testAddLiquidityMultipleProviders() public {
        // First provider
        vm.startPrank(alice);
        protocol.addLiquidity(100 ether, 100 ether);
        vm.stopPrank();

        // Second provider
        vm.startPrank(bob);
        uint256 bobLiquidity = protocol.addLiquidity(50 ether, 50 ether);
        assertGt(bobLiquidity, 0, "Should receive liquidity tokens");
        vm.stopPrank();

        // Verify reserves
        (uint256 reserve0, uint256 reserve1) = protocol.getReserves();
        assertEq(reserve0, 150 ether, "Incorrect reserve0 after multiple providers");
        assertEq(reserve1, 150 ether, "Incorrect reserve1 after multiple providers");
    }
}