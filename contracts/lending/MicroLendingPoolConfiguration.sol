
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import {LendingPool} from "./MicroLendingPool.sol";


contract PoolConfigurator is Ownable {
    LendingPool public lendingPool;

    event CollateralFactorUpdated(address vault, uint256 newFactor);
    event LiquidationThresholdUpdated(address vault, uint256 newThreshold);
    event LiquidationBonusUpdated(address vault, uint256 newBonus);
    event DepositCapUpdated(address vault, uint256 newCap);

    constructor(address _lendingPool, address owner) {
        lendingPool = LendingPool(_lendingPool);
        transferOwnership(owner);
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