// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAaveLendingPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract AaveYieldStrategy is ReentrancyGuard, Ownable, AccessControl {
    IERC20 public usdtToken;
    IAaveLendingPool public aaveLendingPool;
    IERC20 public aUsdtToken;

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _aaveLendingPool, address _aUsdtToken, address owner){
        usdtToken = IERC20(_usdtToken);
        aaveLendingPool = IAaveLendingPool(_aaveLendingPool);
        aUsdtToken = IERC20(_aUsdtToken);
        transferOwnership(owner);

        _setupRole(USER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(USER_ROLE, owner);
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(aaveLendingPool), amount);
        aaveLendingPool.supply(address(usdtToken), amount, address(this), 0);
        emit Deposited(amount);
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        aaveLendingPool.withdraw(address(usdtToken), amount, msg.sender);
        emit Withdrawn(amount);
    }

    function harvestYield() external onlyRole(USER_ROLE) nonReentrant {
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