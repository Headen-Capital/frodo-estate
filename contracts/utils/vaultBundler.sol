// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../FrodoEstateVault.sol";

contract EstatesBundler {
    IERC20 public usdcToken;

    struct BundleInfo {
        address[] vaults;
        uint256[] amounts;
    }

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }

    function buyBundle(BundleInfo memory bundle) external {
        require(bundle.vaults.length == bundle.amounts.length, "Invalid bundle info");

        uint256 totalCost = 0;
        for (uint i = 0; i < bundle.vaults.length; i++) {
            FrodoEstateVault vault = FrodoEstateVault(bundle.vaults[i]);
            uint256 cost = vault.getTokenPrice(bundle.amounts[i]);
            totalCost += cost;
        }

        require(usdcToken.transferFrom(msg.sender, address(this), totalCost), "USDC transfer failed");

        for (uint i = 0; i < bundle.vaults.length; i++) {
            FrodoEstateVault vault = FrodoEstateVault(bundle.vaults[i]);
            usdcToken.approve(address(vault), vault.getTokenPrice(bundle.amounts[i]));
            vault.buyTokens(bundle.amounts[i]);
            vault.transfer(msg.sender, bundle.amounts[i]);
        }
    }
}