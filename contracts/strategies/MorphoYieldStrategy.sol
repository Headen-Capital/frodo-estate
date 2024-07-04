// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


interface IMorphoLendingPool {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function balanceOf(address user) external view returns (uint256 assets);
}

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

contract MorphoYieldStrategy is ReentrancyGuard, Ownable, AccessControl {
    IERC20 public usdtToken;
    IMorphoLendingPool public metaMorphoVault;
    IERC20 public morphoToken;

    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 amount);

    constructor(address _usdtToken, address _metaMorphoVault, address _morphoToken, address owner) {
        usdtToken = IERC20(_usdtToken);
        metaMorphoVault = IMorphoLendingPool(_metaMorphoVault);
        morphoToken = IERC20(_morphoToken);
        transferOwnership(owner);

        _setupRole(USER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(USER_ROLE, owner);
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE)  nonReentrant {
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        usdtToken.approve(address(metaMorphoVault), amount);
        metaMorphoVault.deposit(amount, address(this));
        emit Deposited(amount);
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE)  nonReentrant {
        metaMorphoVault.withdraw(amount, msg.sender, address(this));
        // require(usdtToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(amount);
    }

    function harvestYield() external onlyRole(USER_ROLE)  nonReentrant {
        emit YieldHarvested(0);
    }

    function getTotalValue() external view returns (uint256) {
        return metaMorphoVault.convertToAssets(metaMorphoVault.balanceOf(address(this)));
    }
}