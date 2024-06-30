// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAaveLendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract AaveYieldStrategy is ReentrancyGuard, Ownable {
    IERC20 public usdtToken;
    IAaveLendingPool public aaveLendingPool;
    IERC20 public aUsdtToken;

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _aaveLendingPool, address _aUsdtToken) {
        usdtToken = IERC20(_usdtToken);
        aaveLendingPool = IAaveLendingPool(_aaveLendingPool);
        aUsdtToken = IERC20(_aUsdtToken);
    }

    function deposit(uint256 amount) external onlyOwner nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(aaveLendingPool), amount);
        aaveLendingPool.deposit(address(usdtToken), amount, address(this), 0);
        emit Deposited(amount);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        aaveLendingPool.withdraw(address(usdtToken), amount, address(this));
        require(usdtToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(amount);
    }

    function harvestYield() external onlyOwner nonReentrant {
        uint256 aBalance = aUsdtToken.balanceOf(address(this));
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        uint256 yieldAmount = aBalance - usdtBalance;
        if (yieldAmount > 0) {
            aaveLendingPool.withdraw(address(usdtToken), yieldAmount, address(this));
            require(usdtToken.transfer(msg.sender, yieldAmount), "Transfer failed");
            emit YieldHarvested(yieldAmount);
        }
    }

    function getTotalValue() external view returns (uint256) {
        return aUsdtToken.balanceOf(address(this));
    }
}