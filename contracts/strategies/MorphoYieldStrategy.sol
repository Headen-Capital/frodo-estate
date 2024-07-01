// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface IMorphoLendingPool {
    function supply(address underlying, uint256 amount) external;
    function withdraw(address underlying, uint256 amount) external;
    function claimRewards() external;
}

contract MorphoYieldStrategy is ReentrancyGuard, Ownable, AccessControl {
    IERC20 public usdtToken;
    IMorphoLendingPool public morphoLendingPool;
    IERC20 public morphoToken;

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _morphoLendingPool, address _morphoToken, address owner) {
        usdtToken = IERC20(_usdtToken);
        morphoLendingPool = IMorphoLendingPool(_morphoLendingPool);
        morphoToken = IERC20(_morphoToken);
        transferOwnership(owner);

        _setupRole(USER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(USER_ROLE, owner);
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE)  nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(morphoLendingPool), amount);
        morphoLendingPool.supply(address(usdtToken), amount);
        emit Deposited(amount);
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE)  nonReentrant {
        morphoLendingPool.withdraw(address(usdtToken), amount);
        require(usdtToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(amount);
    }

    function harvestYield() external onlyRole(USER_ROLE)  nonReentrant {
        uint256 balanceBefore = morphoToken.balanceOf(address(this));
        morphoLendingPool.claimRewards();
        uint256 yieldAmount = morphoToken.balanceOf(address(this)) - balanceBefore;
        if (yieldAmount > 0) {
            require(morphoToken.transfer(msg.sender, yieldAmount), "Transfer failed");
            emit YieldHarvested(yieldAmount);
        }
    }

    function getTotalValue() external view returns (uint256) {
        // placeholder
        return usdtToken.balanceOf(address(this));
    }
}