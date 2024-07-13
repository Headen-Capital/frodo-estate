// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICollateralOracleSentinel {
    event VaultRegistered(address vault);
    event CollateralUpdated(address user, address vault, uint256 amount);

    function registeredVaults(address vault) external view returns (bool);
    function priceOracles(address vault) external view returns (address);
    function userCollateral(address user, address vault) external view returns (uint256);

    function registerVault(address _vault, address _priceOracle) external;
    function updateCollateral(address _user, address _vault, uint256 _amount) external;
    function getCollateralValue(address _user) external view returns (uint256);
    function setPriceOracle(address _vault, address _newOracle) external;
    function getPrice(address _vault) external view returns (uint256);
}