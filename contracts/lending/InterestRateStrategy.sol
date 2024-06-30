// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract InterestRateStrategy {
    uint256 public constant OPTIMAL_UTILIZATION_RATE = 80; // 80%
    uint256 public constant BASE_RATE = 2; // 2%
    uint256 public constant SLOPE1 = 10; // 10%
    uint256 public constant SLOPE2 = 100; // 100%

    function getSupplyRate(uint256 _totalSupplied, uint256 _totalBorrowed) public pure returns (uint256) {
        uint256 utilizationRate = _totalSupplied > 0 ? (_totalBorrowed * 100) / _totalSupplied : 0;
        uint256 borrowRate = getBorrowRate(_totalSupplied, _totalBorrowed);
        return (borrowRate * utilizationRate) / 100;
    }

    function getBorrowRate(uint256 _totalSupplied, uint256 _totalBorrowed) public pure returns (uint256) {
        uint256 utilizationRate = _totalSupplied > 0 ? (_totalBorrowed * 100) / _totalSupplied : 0;
        
        if (utilizationRate <= OPTIMAL_UTILIZATION_RATE) {
            return BASE_RATE + (utilizationRate * SLOPE1) / OPTIMAL_UTILIZATION_RATE;
        } else {
            uint256 excessUtilization = utilizationRate - OPTIMAL_UTILIZATION_RATE;
            return BASE_RATE + SLOPE1 + (excessUtilization * SLOPE2) / (100 - OPTIMAL_UTILIZATION_RATE);
        }
    }
}