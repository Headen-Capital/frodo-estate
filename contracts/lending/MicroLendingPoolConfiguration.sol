// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

// contract LendingPoolConfigurator is Ownable {
//     uint256 public collateralFactor = 75; // 75%
//     uint256 public liquidationThreshold = 80; // 80%
//     uint256 public liquidationBonus = 5; // 5%

//     event CollateralFactorUpdated(uint256 newFactor);
//     event LiquidationThresholdUpdated(uint256 newThreshold);
//     event LiquidationBonusUpdated(uint256 newBonus);

//     function setCollateralFactor(uint256 _newFactor) external onlyOwner {
//         require(_newFactor <= 100, "Factor must be <= 100");
//         collateralFactor = _newFactor;
//         emit CollateralFactorUpdated(_newFactor);
//     }

//     function setLiquidationThreshold(uint256 _newThreshold) external onlyOwner {
//         require(_newThreshold <= 100, "Threshold must be <= 100");
//         liquidationThreshold = _newThreshold;
//         emit LiquidationThresholdUpdated(_newThreshold);
//     }

//     function setLiquidationBonus(uint256 _newBonus) external onlyOwner {
//         require(_newBonus <= 50, "Bonus must be <= 50");
//         liquidationBonus = _newBonus;
//         emit LiquidationBonusUpdated(_newBonus);
//     }

//     function getCollateralFactor() external view returns (uint256) {
//         return collateralFactor;
//     }

//     function getLiquidationThreshold() external view returns (uint256) {
//         return liquidationThreshold;
//     }

//     function getLiquidationBonus() external view returns (uint256) {
//         return liquidationBonus;
//     }
// }

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import {LendingPool} from "./MicroLendingPool.sol";


contract PoolConfigurator is Ownable {
    LendingPool public lendingPool;

    event CollateralFactorUpdated(address vault, uint256 newFactor);
    event LiquidationThresholdUpdated(address vault, uint256 newThreshold);
    event LiquidationBonusUpdated(address vault, uint256 newBonus);
    event DepositCapUpdated(address vault, uint256 newCap);

    constructor(address _lendingPool) {
        lendingPool = LendingPool(_lendingPool);
    }

    function setCollateralFactor(address _vault, uint256 _newFactor) external onlyOwner {
        lendingPool.setCollateralFactor(_vault, _newFactor);
        emit CollateralFactorUpdated(_vault, _newFactor);
    }

    function setLiquidationThreshold(address _vault, uint256 _newThreshold) external onlyOwner {
        lendingPool.setLiquidationThreshold(_vault, _newThreshold);
        emit LiquidationThresholdUpdated(_vault, _newThreshold);
    }

    function setLiquidationBonus(address _vault, uint256 _newBonus) external onlyOwner {
        lendingPool.setLiquidationBonus(_vault, _newBonus);
        emit LiquidationBonusUpdated(_vault, _newBonus);
    }

    function setDepositCap(address _vault, uint256 _newCap) external onlyOwner {
        lendingPool.setDepositCap(_vault, _newCap);
        emit DepositCapUpdated(_vault, _newCap);
    }
}