// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract TestProtocol {
    // Token pair for the pool
    IERC20 public token0;
    IERC20 public token1;
    
    // Pool reserves
    uint256 public reserve0;
    uint256 public reserve1;
    
    // Total liquidity tokens
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;
    
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }
    
    // Add liquidity to the pool
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidityMinted) {
        // Transfer tokens to the contract
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);
        
        // Calculate liquidity tokens to mint
        if (totalLiquidity == 0) {
            liquidityMinted = Math.sqrt(amount0 * amount1);
        } else {
            liquidityMinted = Math.min(
                (amount0 * totalLiquidity) / reserve0,
                (amount1 * totalLiquidity) / reserve1
            );
        }
        
        require(liquidityMinted > 0, "Insufficient liquidity minted");
        
        // Update reserves and liquidity
        reserve0 += amount0;
        reserve1 += amount1;
        totalLiquidity += liquidityMinted;
        liquidity[msg.sender] += liquidityMinted;
        
        return liquidityMinted;
    }
    
    // Perform a swap
    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == address(token0) || tokenIn == address(token1), "Invalid token");
        require(amountIn > 0, "Invalid amount");
        
        bool isToken0 = tokenIn == address(token0);
        (IERC20 tokenInput, IERC20 tokenOutput) = isToken0 ? (token0, token1) : (token1, token0);
        (uint256 reserveIn, uint256 reserveOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        
        // Transfer input tokens to contract
        tokenInput.transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate output amount using constant product formula
        // dx * dy = k
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        amountOut = (amountInWithFee * reserveOut) / ((reserveIn * 1000) + amountInWithFee);
        
        // Update reserves
        if (isToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
        
        // Transfer output tokens to user
        tokenOutput.transfer(msg.sender, amountOut);
        
        return amountOut;
    }
    
    // Remove liquidity from the pool
    function removeLiquidity(uint256 liquidityAmount) external returns (uint256 amount0, uint256 amount1) {
        require(liquidity[msg.sender] >= liquidityAmount, "Insufficient liquidity");
        
        // Calculate token amounts to return
        amount0 = (liquidityAmount * reserve0) / totalLiquidity;
        amount1 = (liquidityAmount * reserve1) / totalLiquidity;
        
        // Update state
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;
        reserve0 -= amount0;
        reserve1 -= amount1;
        
        // Transfer tokens back to user
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        
        return (amount0, amount1);
    }
    
    // View functions
    function getReserves() external view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }
    
    function getTokens() external view returns (address, address) {
        return (address(token0), address(token1));
    }
}

// Simple math library for liquidity calculations
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
