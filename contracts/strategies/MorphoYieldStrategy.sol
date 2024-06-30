// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMorphoLendingPool {
    function supply(address underlying, uint256 amount) external;
    function withdraw(address underlying, uint256 amount) external;
    function claimRewards() external;
}

contract MorphoYieldStrategy is ReentrancyGuard, Ownable {
    IERC20 public usdtToken;
    IMorphoLendingPool public morphoLendingPool;
    IERC20 public morphoToken;

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _morphoLendingPool, address _morphoToken) {
        usdtToken = IERC20(_usdtToken);
        morphoLendingPool = IMorphoLendingPool(_morphoLendingPool);
        morphoToken = IERC20(_morphoToken);
    }

    function deposit(uint256 amount) external onlyOwner nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(morphoLendingPool), amount);
        morphoLendingPool.supply(address(usdtToken), amount);
        emit Deposited(amount);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        morphoLendingPool.withdraw(address(usdtToken), amount);
        require(usdtToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(amount);
    }

    function harvestYield() external onlyOwner nonReentrant {
        uint256 balanceBefore = morphoToken.balanceOf(address(this));
        morphoLendingPool.claimRewards();
        uint256 yieldAmount = morphoToken.balanceOf(address(this)) - balanceBefore;
        if (yieldAmount > 0) {
            require(morphoToken.transfer(msg.sender, yieldAmount), "Transfer failed");
            emit YieldHarvested(yieldAmount);
        }
    }

    function getTotalValue() external view returns (uint256) {
        // This is a simplified calculation. In reality, you'd need to get the exchange rate
        // between USDT and Morpho's interest-bearing token.
        return usdtToken.balanceOf(address(this));
    }
}