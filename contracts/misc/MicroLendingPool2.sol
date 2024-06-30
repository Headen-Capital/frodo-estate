// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import {InterestRateStrategy} from "./InterestRateStrategy.sol";
// import {CollateralOracleSentinel} from "./OracleSentinel.sol";
// import {LPToken} from "./LPToken.sol";
// import {DebtToken} from "./DebtToken.sol";
// import {PoolConfigurator} from "./MicroLendingPoolConfiguration.sol";

// contract LendingPool is ReentrancyGuard, Ownable {
//     using SafeMath for uint256;

//     IERC20 public underlyingAsset;
//     InterestRateStrategy public interestRateStrategy;
//     CollateralOracleSentinel public oracleSentinel;
//     LPToken public lpToken;
//     DebtToken public debtToken;

//     // Pool configuration
//     uint256 public collateralFactor = 75; // 75%
//     uint256 public liquidationThreshold = 80; // 80%
//     uint256 public liquidationBonus = 5; // 5%

//     struct UserAccount {
//         uint256 supplied;
//         uint256 borrowed;
//         uint256 lastInterestTimestamp;
//     }

//     mapping(address => UserAccount) public userAccounts;

//     uint256 public totalSupplied;
//     uint256 public totalBorrowed;
//     uint256 public lastGlobalInterestTimestamp;

//     event Supplied(address indexed user, uint256 amount);
//     event Borrowed(address indexed user, uint256 amount);
//     event Repaid(address indexed user, uint256 amount, uint256 interest);
//     event Withdrawn(address indexed user, uint256 amount);
//     event ConfigurationUpdated(uint256 collateralFactor, uint256 liquidationThreshold, uint256 liquidationBonus);

//     constructor(
//         address _underlyingAsset,
//         address _interestRateStrategy,
//         address _oracleSentinel,
//         address _lpToken,
//         address _debtToken
//     ) {
//         underlyingAsset = IERC20(_underlyingAsset);
//         interestRateStrategy = InterestRateStrategy(_interestRateStrategy);
//         oracleSentinel = CollateralOracleSentinel(_oracleSentinel);
//         lpToken = LPToken(_lpToken);
//         debtToken = DebtToken(_debtToken);
//         lastGlobalInterestTimestamp = block.timestamp;
//     }

//     function supply(uint256 _amount) external nonReentrant {
//         require(_amount > 0, "Amount must be greater than 0");
//         require(underlyingAsset.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

//         updateGlobalInterest();
//         userAccounts[msg.sender].supplied = userAccounts[msg.sender].supplied.add(_amount);
//         totalSupplied = totalSupplied.add(_amount);

//         lpToken.mint(msg.sender, _amount);

//         emit Supplied(msg.sender, _amount);
//     }

//     function borrow(uint256 _amount) external nonReentrant {
//         require(_amount > 0, "Amount must be greater than 0");
//         require(totalSupplied.sub(totalBorrowed) >= _amount, "Not enough liquidity");
//         require(checkHealth(msg.sender, _amount), "Unhealthy borrow position");

//         updateGlobalInterest();
//         UserAccount storage account = userAccounts[msg.sender];
//         account.borrowed = account.borrowed.add(_amount);
//         account.lastInterestTimestamp = block.timestamp;
//         totalBorrowed = totalBorrowed.add(_amount);

//         debtToken.mint(msg.sender, _amount);
//         require(underlyingAsset.transfer(msg.sender, _amount), "Transfer failed");

//         emit Borrowed(msg.sender, _amount);
//     }

//     function repay(uint256 _amount) external nonReentrant {
//         require(_amount > 0, "Amount must be greater than 0");
//         updateGlobalInterest();
        
//         UserAccount storage account = userAccounts[msg.sender];
//         uint256 interest = calculateInterest(account.borrowed, account.lastInterestTimestamp);
//         uint256 totalDebt = account.borrowed.add(interest);
//         uint256 repayAmount = _amount > totalDebt ? totalDebt : _amount;

//         require(underlyingAsset.transferFrom(msg.sender, address(this), repayAmount), "Transfer failed");

//         uint256 principalRepaid = repayAmount > interest ? repayAmount.sub(interest) : 0;
//         account.borrowed = account.borrowed.sub(principalRepaid);
//         totalBorrowed = totalBorrowed.sub(principalRepaid);
//         account.lastInterestTimestamp = block.timestamp;

//         debtToken.burn(msg.sender, principalRepaid);

//         emit Repaid(msg.sender, principalRepaid, interest);
//     }

//     function withdraw(uint256 _amount) external nonReentrant {
//         require(_amount > 0, "Amount must be greater than 0");
//         updateGlobalInterest();
        
//         UserAccount storage account = userAccounts[msg.sender];
//         require(account.supplied >= _amount, "Insufficient balance");
//         require(totalSupplied.sub(totalBorrowed) >= _amount, "Not enough liquidity");
//         require(checkHealth(msg.sender, 0), "Withdrawal would make position unhealthy");

//         account.supplied = account.supplied.sub(_amount);
//         totalSupplied = totalSupplied.sub(_amount);

//         lpToken.burn(msg.sender, _amount);
//         require(underlyingAsset.transfer(msg.sender, _amount), "Transfer failed");

//         emit Withdrawn(msg.sender, _amount);
//     }

//     function checkHealth(address _user, uint256 _additionalBorrow) public view returns (bool) {
//         UserAccount memory account = userAccounts[_user];
//         uint256 totalBorrowedData = account.borrowed.add(_additionalBorrow);
//         uint256 collateralValue = getCollateralValue(_user);
//         return collateralValue.mul(collateralFactor).div(100) >= totalBorrowedData;
//     }

//     function getCollateralValue(address _user) public view returns (uint256) {
//         return oracleSentinel.getCollateralValue(_user);
//     }

//     function getCurrentLTV(address _user) public view returns (uint256) {
//         UserAccount memory account = userAccounts[_user];
//         uint256 collateralValue = getCollateralValue(_user);
//         if (collateralValue == 0) return 0;
//         return account.borrowed.mul(100).div(collateralValue);
//     }

//     function getSuppliedPlusYield(address _user) public view returns (uint256) {
//         UserAccount memory account = userAccounts[_user];
//         uint256 yield = calculateInterest(account.supplied, lastGlobalInterestTimestamp);
//         return account.supplied.add(yield);
//     }

//     function getBorrowedPlusInterest(address _user) public view returns (uint256) {
//         UserAccount memory account = userAccounts[_user];
//         uint256 interest = calculateInterest(account.borrowed, account.lastInterestTimestamp);
//         return account.borrowed.add(interest);
//     }

//     function getSupplyAPR() public view returns (uint256) {
//         return interestRateStrategy.getSupplyRate(totalSupplied, totalBorrowed);
//     }

//     function getBorrowAPR() public view returns (uint256) {
//         return interestRateStrategy.getBorrowRate(totalSupplied, totalBorrowed);
//     }

//     function updateConfiguration(uint256 _collateralFactor, uint256 _liquidationThreshold, uint256 _liquidationBonus) external onlyOwner {
//         require(_collateralFactor <= 100, "Collateral factor must be <= 100");
//         require(_liquidationThreshold <= 100, "Liquidation threshold must be <= 100");
//         require(_liquidationBonus <= 50, "Liquidation bonus must be <= 50");
        
//         collateralFactor = _collateralFactor;
//         liquidationThreshold = _liquidationThreshold;
//         liquidationBonus = _liquidationBonus;

//         emit ConfigurationUpdated(_collateralFactor, _liquidationThreshold, _liquidationBonus);
//     }

//     function updateGlobalInterest() internal {
//         uint256 timeDelta = block.timestamp.sub(lastGlobalInterestTimestamp);
//         if (timeDelta > 0) {
//             uint256 interestRate = getSupplyAPR();
//             uint256 interest = totalSupplied.mul(interestRate).mul(timeDelta).div(365 days).div(100);
//             totalSupplied = totalSupplied.add(interest);
//             lastGlobalInterestTimestamp = block.timestamp;
//         }
//     }

//     function calculateInterest(uint256 _amount, uint256 _lastTimestamp) internal view returns (uint256) {
//         uint256 timeDelta = block.timestamp.sub(_lastTimestamp);
//         uint256 interestRate = getBorrowAPR();
//         return _amount.mul(interestRate).mul(timeDelta).div(365 days).div(100);
//     }
// }