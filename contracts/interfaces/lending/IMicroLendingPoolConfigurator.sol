// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolConfigurator {
    event CollateralFactorUpdated(address vault, uint256 newFactor);
    event LiquidationThresholdUpdated(address vault, uint256 newThreshold);
    event LiquidationBonusUpdated(address vault, uint256 newBonus);
    event DepositCapUpdated(address vault, uint256 newCap);
    event CloseFactorUpdated(uint256 newFactor);
    event LendingPoolSet(address lendingPool);

    function lendingPool() external view returns (address);

    function setLendingPool(address _lendingPool) external;

    function setCollateralFactor(address _vault, uint256 _newFactor) external;

    function setLiquidationThreshold(address _vault, uint256 _newThreshold) external;

    function setLiquidationBonus(address _vault, uint256 _newBonus) external;

    function setDepositCap(address _vault, uint256 _newCap) external;

    function setCloseFactor(uint256 _newCloseFactor) external;
}