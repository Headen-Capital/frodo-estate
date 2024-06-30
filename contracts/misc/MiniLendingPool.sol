// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./FrodoEstateVault.sol";

// contract MorphoInspiredLendingPool is ReentrancyGuard, Ownable {
//     IERC20 public usdtToken;
//     mapping(address => mapping(address => uint256)) public collateralAmount;
//     mapping(address => uint256) public borrowedAmount;

//     uint256 public constant COLLATERAL_FACTOR = 75; // 75% LTV

//     event Collateralized(address indexed user, address indexed vault, uint256 amount);
//     event Borrowed(address indexed user, uint256 amount);
//     event Repaid(address indexed user, uint256 amount);
//     event CollateralWithdrawn(address indexed user, address indexed vault, uint256 amount);

//     constructor(address _usdtToken) {
//         usdtToken = IERC20(_usdtToken);
//     }

//     function depositCollateral(address vault, uint256 amount) external nonReentrant {
//         FrodoEstateVault vaultContract = FrodoEstateVault(vault);
//         require(vaultContract.transferFrom(msg.sender, address(this), amount), "Transfer failed");

//         collateralAmount[msg.sender][vault] += amount;

//         emit Collateralized(msg.sender, vault, amount);
//     }

//     function borrow(uint256 amount) external nonReentrant {
//         uint256 collateralValue = getCollateralValue(msg.sender);
//         uint256 maxBorrow = (collateralValue * COLLATERAL_FACTOR) / 100;
//         require(borrowedAmount[msg.sender] + amount <= maxBorrow, "Insufficient collateral");

//         require(usdtToken.transfer(msg.sender, amount), "Transfer failed");
//         borrowedAmount[msg.sender] += amount;

//         emit Borrowed(msg.sender, amount);
//     }

//     function repay(uint256 amount) external nonReentrant {
//         require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
//         borrowedAmount[msg.sender] -= amount;

//         emit Repaid(msg.sender, amount);
//     }

//     function withdrawCollateral(address vault, uint256 amount) external nonReentrant {
//         require(collateralAmount[msg.sender][vault] >= amount, "Insufficient collateral");

//         uint256 newCollateralValue = getCollateralValue(msg.sender) - (amount * FrodoEstateVault(vault).getTokenValue());
//         uint256 maxBorrow = (newCollateralValue * COLLATERAL_FACTOR) / 100;
//         require(borrowedAmount[msg.sender] <= maxBorrow, "Collateral ratio would be too low");

//         FrodoEstateVault vaultContract = FrodoEstateVault(vault);
//         require(vaultContract.transfer(msg.sender, amount), "Transfer failed");

//         collateralAmount[msg.sender][vault] -= amount;

//         emit CollateralWithdrawn(msg.sender, vault, amount);
//     }

//     function getCollateralValue(address user) public view returns (uint256) {
//         uint256 totalValue = 0;
//         address[] memory vaults = getCollateralVaults(user);
//         for (uint i = 0; i < vaults.length; i++) {
//             FrodoEstateVault vault = FrodoEstateVault(vaults[i]);
//             totalValue += collateralAmount[user][vaults[i]] * vault.getTokenValue();
//         }
//         return totalValue;
//     }

//     function getCollateralVaults(address user) public view returns (address[] memory) {
//         // This function should return an array of vault addresses where the user has collateral
//         // Implementation depends on how you're tracking this information
//     }
// }