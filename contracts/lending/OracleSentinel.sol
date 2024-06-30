// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceOracle {
    function getPrice(address asset) external view returns (uint256);
}

contract CollateralOracleSentinel is Ownable {
    mapping(address => bool) public registeredVaults;
    mapping(address => IPriceOracle) public priceOracles;
    mapping(address => mapping(address => uint256)) public userCollateral;
    address[] vaults;

    event VaultRegistered(address vault);
    event CollateralUpdated(address user, address vault, uint256 amount);

    constructor() {}

    function registerVault(address _vault, address _priceOracle) external onlyOwner {
        registeredVaults[_vault] = true;
        priceOracles[_vault] = IPriceOracle(_priceOracle);
        vaults.push(_vault);
        emit VaultRegistered(_vault);
    }

    function updateCollateral(address _user, address _vault, uint256 _amount) external {
        require(registeredVaults[_vault], "Vault not registered");
        require(msg.sender == _vault, "Only registered vault can update");
        userCollateral[_user][_vault] = _amount;
        emit CollateralUpdated(_user, _vault, _amount);
    }

    function getCollateralValue(address _user) external view returns (uint256) {
        uint256 totalValue = 0;
        for (uint i = 0; i < vaults.length; i++) {
            address vault = vaults[i];
            IPriceOracle priceOracle = priceOracles[vault];
            uint256 amount = userCollateral[_user][vault];
            uint256 price = priceOracle.getPrice(vault);
            totalValue += amount * price;
        }
        return totalValue;
    }

    function setPriceOracle(address _vault, address _newOracle) external onlyOwner {
        priceOracles[_vault] = IPriceOracle(_newOracle);
    }

     function getPrice(address _vault) external view returns (uint256) {
        IPriceOracle priceOracle = priceOracles[_vault];
        return priceOracle.getPrice(_vault);
    }
}