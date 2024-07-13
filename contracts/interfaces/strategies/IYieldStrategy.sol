// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IYieldStrategy {
    // event Deposited(uint256 amount);
    // event Withdrawn(uint256 amount);
    // event YieldHarvested(uint256 amount); // many different events

    function usdtToken() external view returns (address);
    function aaveLendingPool() external view returns (address);
    function aUsdtToken() external view returns (address);
    function USER_ROLE() external view returns (bytes32);

    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function harvestYield() external;
    function getTotalValue() external view returns (uint256);
}