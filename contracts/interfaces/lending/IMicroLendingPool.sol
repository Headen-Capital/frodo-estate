// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
// import "@openzeppelin/contracts/security/IPausable.sol";

interface ILendingPool is IAccessControl {
    // Structs
    struct VaultConfig {
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 depositCap;
    }

    struct UserAccount {
        uint256 supplied;
        uint256 borrowed;
        uint256 lastInterestTimestamp;
    }

    // Events
    event Supplied(address indexed user, uint256 amount);
    event Borrowed(address indexed user, address vault, uint256 amount);
    event Repaid(address indexed user, uint256 amount, uint256 interest);
    event Withdrawn(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, address indexed vault, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed vault, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed user, address indexed vault, uint256 debtRepaid, uint256 collateralLiquidated);
    event InterestAccrued(uint256 supplyInterest, uint256 borrowInterest);

    // State Variables
    function CONFIGURATOR_ROLE() external view returns (bytes32);
    function underlyingAsset() external view returns (IERC20);
    function interestRateStrategy() external view returns (address);
    function oracleSentinel() external view returns (address);
    function lpToken() external view returns (address);
    function debtToken() external view returns (address);
    function poolConfigurator() external view returns (address);
    function vaults(uint256 index) external view returns (address);
    function userAccounts(address user) external view returns (UserAccount memory);
    function vaultConfigs(address vault) external view returns (VaultConfig memory);
    function totalCollateralDeposited(address vault) external view returns (uint256);
    function totalSupplied() external view returns (uint256);
    function totalBorrowed() external view returns (uint256);
    function lastGlobalInterestTimestamp() external view returns (uint256);
    function closeFactor() external view returns (uint256);

    // Functions
    function setPoolConfigurator(address _poolConfigurator) external;
    function setTokens(address _lpToken, address _debtToken) external;
    function setIRStrategy(address _interestRateStrategy) external;
    function supply(uint256 _amount) external;
    function borrow(address _vault, uint256 _amount) external;
    function repay(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function depositCollateral(address _vault, uint256 _amount) external;
    function withdrawCollateral(address _vault, uint256 _amount) external;
    function liquidate(address _user, address _vault, uint256 _debtToCover) external;
    function checkHealth(address _user) external view returns (bool);
    function checkHealth(address _user, address _vault) external view returns (bool);
    function getWeightedLiquidationThreshold(address _user) external view returns (uint256);
    function getCollateralValueInUSD(address _user, address _vault) external view returns (uint256);
    function getTotalCollateralValueInUSD(address _user) external view returns (uint256);
    function getCurrentLTV(address _user) external view returns (uint256);
    function getSuppliedPlusYield(address _user) external view returns (uint256);
    function getBorrowedPlusInterest(address _user) external view returns (uint256);
    function getSupplyAPR() external view returns (uint256);
    function getBorrowAPR() external view returns (uint256);
    function setCollateralFactor(address _vault, uint256 _newFactor) external;
    function setLiquidationThreshold(address _vault, uint256 _newThreshold) external;
    function setLiquidationBonus(address _vault, uint256 _newBonus) external;
    function setDepositCap(address _vault, uint256 _newCap) external;
    function setCloseFactor(uint256 _newCloseFactor) external;
    function addSupportedVault(address _vault, uint256 _collateralFactor, uint256 _liquidationThreshold, uint256 _liquidationBonus, uint256 _depositCap) external;
    function pause() external;
    function unpause() external;
    function flashLoan(address receiver, uint256 amount, bytes calldata params) external;
    function getSupportedVaults() external view returns (address[] memory);
    function getVaultConfig(address _vault) external view returns (VaultConfig memory);
    function updateOracle(address _newOracle) external;
}