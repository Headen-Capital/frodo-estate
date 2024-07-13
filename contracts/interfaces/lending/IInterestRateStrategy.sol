// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IInterestRateStrategy {
    event InterestRateUpdated(
        uint256 baseRate,
        uint256 optimalUtilization,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    );

    function UTILIZATION_PRECISION() external pure returns (uint256);
    function RATE_PRECISION() external pure returns (uint256);

    function baseRate() external view returns (uint256);
    function optimalUtilization() external view returns (uint256);
    function variableRateSlope1() external view returns (uint256);
    function variableRateSlope2() external view returns (uint256);
    function adaptiveSpeedFactor() external view returns (uint256);

    function getSupplyRate(uint256 _totalSupplied, uint256 _totalBorrowed) external view returns (uint256);
    function getBorrowRate(uint256 _totalSupplied, uint256 _totalBorrowed) external view returns (uint256);
    function updateInterestRateModel(address _pool) external;
}