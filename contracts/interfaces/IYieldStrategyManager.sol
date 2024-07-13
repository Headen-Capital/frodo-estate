// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IYieldStrategyManager is IERC4626 {
    // Events
    event YieldHarvested(uint256 amount);
    event AllocationsUpdated(uint256 aave, uint256 morpho, uint256 uniswap);
    event StrategiesUpdated(address aave, address morpho, address uniswap);

    // State Variables
    function aaveStrategy() external view returns (address);
    function morphoStrategy() external view returns (address);
    function uniswapStrategy() external view returns (address);
    function aaveAllocation() external view returns (uint256);
    function morphoAllocation() external view returns (uint256);
    function uniswapAllocation() external view returns (uint256);
    function totalAssetsLocked() external view returns (uint256);

    // Functions
    function setAllocations(uint256 _aave, uint256 _morpho, uint256 _uniswap) external;
    function updateStrategies(address _aaveStrategy, address _morphoStrategy, address _uniswapStrategy) external;
    function totalStrategyAssets() external view returns (uint256);
    function harvestYields() external;

}