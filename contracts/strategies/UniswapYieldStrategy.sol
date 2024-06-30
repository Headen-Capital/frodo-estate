// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV3Pool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data) external returns (uint256 amount0, uint256 amount1);
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);
    function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1);
}

contract UniswapYieldStrategy is ReentrancyGuard, Ownable {
    IERC20 public usdtToken;
    IUniswapV3Pool public uniswapPool;
    int24 public tickLower;
    int24 public tickUpper;

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _uniswapPool, int24 _tickLower, int24 _tickUpper) {
        usdtToken = IERC20(_usdtToken);
        uniswapPool = IUniswapV3Pool(_uniswapPool);
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    function deposit(uint256 amount) external onlyOwner nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(uniswapPool), amount);
        (uint256 amount0, uint256 amount1) = uniswapPool.mint(address(this), tickLower, tickUpper, uint128(amount), "");
        emit Deposited(amount0 + amount1);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        (uint256 amount0, uint256 amount1) = uniswapPool.burn(tickLower, tickUpper, uint128(amount));
        uniswapPool.collect(address(this), tickLower, tickUpper, uint128(amount0), uint128(amount1));
        require(usdtToken.transfer(msg.sender, amount0 + amount1), "Transfer failed");
        emit Withdrawn(amount0 + amount1);
    }

    function harvestYield() external onlyOwner nonReentrant {
        (uint128 amount0, uint128 amount1) = uniswapPool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
        uint256 yieldAmount = amount0 + amount1;
        if (yieldAmount > 0) {
            require(usdtToken.transfer(msg.sender, yieldAmount), "Transfer failed");
            emit YieldHarvested(yieldAmount);
        }
    }

    function getTotalValue() external view returns (uint256) {
        // This is a simplified calculation. In reality, you'd need to calculate the value
        // of the liquidity position based on current pool prices and liquidity.
        return usdtToken.balanceOf(address(this));
    }
}