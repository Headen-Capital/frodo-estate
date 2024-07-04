// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {LendingPool} from "./MicroLendingPool.sol";

contract InterestRateStrategy {
    using Math for uint256;

    uint256 public constant UTILIZATION_PRECISION = 1e5; // 5 decimals
    uint256 public constant RATE_PRECISION = 1e4; // 4 decimals

    uint256 public baseRate; // Base rate (in RATE_PRECISION)
    uint256 public optimalUtilization; // Optimal utilization point (in UTILIZATION_PRECISION)
    uint256 public variableRateSlope1; // Slope of the variable rate before optimal utilization (in RATE_PRECISION)
    uint256 public variableRateSlope2; // Slope of the variable rate after optimal utilization (in RATE_PRECISION)
    uint256 public adaptiveSpeedFactor; // Factor to control the speed of adaptation

    event InterestRateUpdated(
        uint256 baseRate,
        uint256 optimalUtilization,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    );

    constructor(
        uint256 _baseRate,
        uint256 _optimalUtilization,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2,
        uint256 _adaptiveSpeedFactor
    ) {
        baseRate = _baseRate;
        optimalUtilization = _optimalUtilization;
        variableRateSlope1 = _variableRateSlope1;
        variableRateSlope2 = _variableRateSlope2;
        adaptiveSpeedFactor = _adaptiveSpeedFactor;
    }

    function getSupplyRate(uint256 _totalSupplied, uint256 _totalBorrowed) public view returns (uint256) {
        uint256 utilizationRate = _calculateUtilizationRate(_totalSupplied, _totalBorrowed);
        uint256 borrowRate = getBorrowRate(_totalSupplied, _totalBorrowed);
        return (borrowRate * utilizationRate) / UTILIZATION_PRECISION;
    }

    function getBorrowRate(uint256 _totalSupplied, uint256 _totalBorrowed) public view returns (uint256) {
        uint256 utilizationRate = _calculateUtilizationRate(_totalSupplied, _totalBorrowed);
        
        if (utilizationRate <= optimalUtilization) {
            return baseRate + (utilizationRate * variableRateSlope1) / optimalUtilization;
        } else {
            uint256 excessUtilization = utilizationRate - optimalUtilization;
            return baseRate + variableRateSlope1 + (excessUtilization * variableRateSlope2) / (UTILIZATION_PRECISION - optimalUtilization);
        }
    }

    function updateInterestRateModel(address _pool) external {
        _updateInterestRateModel(_pool);
    }

    function _updateInterestRateModel(address _pool) internal {
        uint256 _totalSupplied = LendingPool(_pool).totalSupplied();
        uint256 _totalBorrowed =  LendingPool(_pool).totalBorrowed();
        uint256 currentUtilization = _calculateUtilizationRate(_totalSupplied, _totalBorrowed);
        
        // Adapt the optimal utilization point
        if (currentUtilization > optimalUtilization) {
            optimalUtilization = Math.min(
                optimalUtilization + (adaptiveSpeedFactor * (currentUtilization - optimalUtilization)) / RATE_PRECISION,
                UTILIZATION_PRECISION
            );
        } else {
            optimalUtilization = Math.max(
                optimalUtilization - (adaptiveSpeedFactor * (optimalUtilization - currentUtilization)) / RATE_PRECISION,
                0
            );
        }

        // Adapt the slopes
        if (currentUtilization <= optimalUtilization) {
            variableRateSlope1 = Math.max(
                variableRateSlope1 - (adaptiveSpeedFactor * variableRateSlope1) / RATE_PRECISION,
                0
            );
        } else {
            variableRateSlope2 = Math.min(
                variableRateSlope2 + (adaptiveSpeedFactor * variableRateSlope2) / RATE_PRECISION,
                RATE_PRECISION
            );
        }

        emit InterestRateUpdated(baseRate, optimalUtilization, variableRateSlope1, variableRateSlope2);
    }

    function _calculateUtilizationRate(uint256 _totalSupplied, uint256 _totalBorrowed) internal pure returns (uint256) {
        if (_totalSupplied == 0) return 0;
        return (_totalBorrowed * UTILIZATION_PRECISION) / _totalSupplied;
    }
}