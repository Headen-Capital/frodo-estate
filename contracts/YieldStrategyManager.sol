// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./strategies/AaveYieldStrategy.sol";
import "./strategies/MorphoYieldStrategy.sol";
import "./strategies/UniswapYieldStrategy.sol";

contract YieldStrategyManager is Ownable, ReentrancyGuard {
    IERC20 public usdtToken;
    AaveYieldStrategy public aaveStrategy;
    MorphoYieldStrategy public morphoStrategy;
    UniswapYieldStrategy public uniswapStrategy;

    uint256 public aaveAllocation;
    uint256 public morphoAllocation;
    uint256 public uniswapAllocation;

    mapping(address => uint256) public userShares;
    uint256 public totalShares;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event YieldHarvested(uint256 amount);
    event AllocationsUpdated(uint256 aave, uint256 morpho, uint256 uniswap);

    constructor(
        address _usdtToken,
        address _aaveStrategy,
        address _morphoStrategy,
        address _uniswapStrategy
    ) {
        usdtToken = IERC20(_usdtToken);
        aaveStrategy = AaveYieldStrategy(_aaveStrategy);
        morphoStrategy = MorphoYieldStrategy(_morphoStrategy);
        uniswapStrategy = UniswapYieldStrategy(_uniswapStrategy);

        // Default allocations
        aaveAllocation = 40;
        morphoAllocation = 30;
        uniswapAllocation = 30;
    }

    function setAllocations(uint256 _aave, uint256 _morpho, uint256 _uniswap) external onlyOwner {
        require(_aave + _morpho + _uniswap == 100, "Allocations must sum to 100");
        aaveAllocation = _aave;
        morphoAllocation = _morpho;
        uniswapAllocation = _uniswap;
        emit AllocationsUpdated(_aave, _morpho, _uniswap);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 aaveAmount = (amount * aaveAllocation) / 100;
        uint256 morphoAmount = (amount * morphoAllocation) / 100;
        uint256 uniswapAmount = amount - aaveAmount - morphoAmount;

        usdtToken.approve(address(aaveStrategy), aaveAmount);
        usdtToken.approve(address(morphoStrategy), morphoAmount);
        usdtToken.approve(address(uniswapStrategy), uniswapAmount);

        aaveStrategy.deposit(aaveAmount);
        morphoStrategy.deposit(morphoAmount);
        uniswapStrategy.deposit(uniswapAmount);

        uint256 shares = totalShares == 0 ? amount : (amount * totalShares) / getTotalValue();
        userShares[msg.sender] += shares;
        totalShares += shares;

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 shares) external nonReentrant {
        require(userShares[msg.sender] >= shares, "Insufficient shares");
        uint256 amount = (shares * getTotalValue()) / totalShares;

        uint256 aaveAmount = (amount * aaveAllocation) / 100;
        uint256 morphoAmount = (amount * morphoAllocation) / 100;
        uint256 uniswapAmount = amount - aaveAmount - morphoAmount;

        aaveStrategy.withdraw(aaveAmount);
        morphoStrategy.withdraw(morphoAmount);
        uniswapStrategy.withdraw(uniswapAmount);

        userShares[msg.sender] -= shares;
        totalShares -= shares;

        require(usdtToken.transfer(msg.sender, amount), "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function harvestYields() external nonReentrant {
        uint256 beforeBalance = usdtToken.balanceOf(address(this));

        aaveStrategy.harvestYield();
        morphoStrategy.harvestYield();
        uniswapStrategy.harvestYield();

        uint256 yieldAmount = usdtToken.balanceOf(address(this)) - beforeBalance;
        emit YieldHarvested(yieldAmount);

        // Reinvest the yield
        uint256 aaveAmount = (yieldAmount * aaveAllocation) / 100;
        uint256 morphoAmount = (yieldAmount * morphoAllocation) / 100;
        uint256 uniswapAmount = yieldAmount - aaveAmount - morphoAmount;

        usdtToken.approve(address(aaveStrategy), aaveAmount);
        usdtToken.approve(address(morphoStrategy), morphoAmount);
        usdtToken.approve(address(uniswapStrategy), uniswapAmount);

        aaveStrategy.deposit(aaveAmount);
        morphoStrategy.deposit(morphoAmount);
        uniswapStrategy.deposit(uniswapAmount);
    }

    function getTotalValue() public view returns (uint256) {
        return aaveStrategy.getTotalValue() + morphoStrategy.getTotalValue() + uniswapStrategy.getTotalValue();
    }

    function getUserValue(address user) external view returns (uint256) {
        return (userShares[user] * getTotalValue()) / totalShares;
    }
}