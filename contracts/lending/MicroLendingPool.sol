// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {InterestRateStrategy} from "./InterestRateStrategy.sol";
import {CollateralOracleSentinel} from "./OracleSentinel.sol";
import {LPToken} from "./LPToken.sol";
import {DebtToken} from "./DebtToken.sol";
import {PoolConfigurator} from "./MicroLendingPoolConfiguration.sol";


contract LendingPool is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public underlyingAsset;
    InterestRateStrategy public interestRateStrategy;
    CollateralOracleSentinel public oracleSentinel;
    LPToken public lpToken;
    DebtToken public debtToken;
    PoolConfigurator public poolConfigurator;

    struct VaultConfig {
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 depositCap;
    }

    struct UserAccount {
        uint256 supplied;
        uint256 borrowed;
        uint256 lastInterestTimestamp;
        mapping(address => uint256) collateralBalances;
    }

    mapping(address => UserAccount) public userAccounts;
    mapping(address => VaultConfig) public vaultConfigs;
    mapping(address => uint256) public totalCollateralDeposited;

    uint256 public totalSupplied;
    uint256 public totalBorrowed;
    uint256 public lastGlobalInterestTimestamp;

    event Supplied(address indexed user, uint256 amount);
    event Borrowed(address indexed user, address vault, uint256 amount);
    event Repaid(address indexed user, uint256 amount, uint256 interest);
    event Withdrawn(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, address indexed vault, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed vault, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed user, address indexed vault, uint256 debtRepaid, uint256 collateralLiquidated);

    constructor(
        address _underlyingAsset,
        address _interestRateStrategy,
        address _oracleSentinel,
        address _lpToken,
        address _debtToken
    ) {
        underlyingAsset = IERC20(_underlyingAsset);
        interestRateStrategy = InterestRateStrategy(_interestRateStrategy);
        oracleSentinel = CollateralOracleSentinel(_oracleSentinel);
        lpToken = LPToken(_lpToken);
        debtToken = DebtToken(_debtToken);
        lastGlobalInterestTimestamp = block.timestamp;
    }

    function setPoolConfigurator(address _poolConfigurator) external onlyOwner {
        poolConfigurator = PoolConfigurator(_poolConfigurator);
    }

    function supply(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(underlyingAsset.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        updateGlobalInterest();
        userAccounts[msg.sender].supplied = userAccounts[msg.sender].supplied.add(_amount);
        totalSupplied = totalSupplied.add(_amount);

        lpToken.mint(msg.sender, _amount);

        emit Supplied(msg.sender, _amount);
    }

    function borrow(address _vault, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(totalSupplied.sub(totalBorrowed) >= _amount, "Not enough liquidity");

        updateGlobalInterest();
        UserAccount storage account = userAccounts[msg.sender];
        
        uint256 collateralValue = getCollateralValueInUSD(msg.sender, _vault);
        uint256 maxBorrow = collateralValue.mul(vaultConfigs[_vault].collateralFactor).div(100);
        require(_amount <= maxBorrow, "Borrow amount exceeds allowed limit");

        account.borrowed = account.borrowed.add(_amount);
        account.lastInterestTimestamp = block.timestamp;
        totalBorrowed = totalBorrowed.add(_amount);

        debtToken.mint(msg.sender, _amount);
        require(underlyingAsset.transfer(msg.sender, _amount), "Transfer failed");

        emit Borrowed(msg.sender, _vault, _amount);
    }

    function repay(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        updateGlobalInterest();
        
        UserAccount storage account = userAccounts[msg.sender];
        uint256 interest = calculateInterest(account.borrowed, account.lastInterestTimestamp);
        uint256 totalDebt = account.borrowed.add(interest);
        uint256 repayAmount = _amount > totalDebt ? totalDebt : _amount;

        require(underlyingAsset.transferFrom(msg.sender, address(this), repayAmount), "Transfer failed");

        uint256 principalRepaid = repayAmount > interest ? repayAmount.sub(interest) : 0;
        account.borrowed = account.borrowed.sub(principalRepaid);
        totalBorrowed = totalBorrowed.sub(principalRepaid);
        account.lastInterestTimestamp = block.timestamp;

        debtToken.burn(msg.sender, principalRepaid);

        emit Repaid(msg.sender, principalRepaid, interest);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        updateGlobalInterest();
        
        UserAccount storage account = userAccounts[msg.sender];
        require(account.supplied >= _amount, "Insufficient balance");
        require(totalSupplied.sub(totalBorrowed) >= _amount, "Not enough liquidity");
        require(checkHealth(msg.sender), "Withdrawal would make position unhealthy");

        account.supplied = account.supplied.sub(_amount);
        totalSupplied = totalSupplied.sub(_amount);

        lpToken.burn(msg.sender, _amount);
        require(underlyingAsset.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function depositCollateral(address _vault, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(vaultConfigs[_vault].collateralFactor > 0, "Vault not supported");
        require(totalCollateralDeposited[_vault].add(_amount) <= vaultConfigs[_vault].depositCap, "Deposit cap reached");

        IERC20(_vault).transferFrom(msg.sender, address(this), _amount);
        
        UserAccount storage account = userAccounts[msg.sender];
        account.collateralBalances[_vault] = account.collateralBalances[_vault].add(_amount);
        totalCollateralDeposited[_vault] = totalCollateralDeposited[_vault].add(_amount);

        emit CollateralDeposited(msg.sender, _vault, _amount);
    }

    function withdrawCollateral(address _vault, uint256 _amount) external nonReentrant {
        UserAccount storage account = userAccounts[msg.sender];
        require(account.collateralBalances[_vault] >= _amount, "Insufficient collateral balance");
        
        account.collateralBalances[_vault] = account.collateralBalances[_vault].sub(_amount);
        totalCollateralDeposited[_vault] = totalCollateralDeposited[_vault].sub(_amount);

        require(checkHealth(msg.sender), "Withdrawal would make position unhealthy");

        IERC20(_vault).transfer(msg.sender, _amount);

        emit CollateralWithdrawn(msg.sender, _vault, _amount);
    }

    function liquidate(address _user, address _vault, uint256 _debtToCover) external nonReentrant {
        require(_debtToCover > 0, "Debt to cover must be greater than 0");
        require(!checkHealth(_user), "User position is healthy");

        UserAccount storage account = userAccounts[_user];
        uint256 userDebt = getBorrowedPlusInterest(_user);
        uint256 maxLiquidation = userDebt.mul(50).div(100); // Max 50% of the user's debt
        uint256 actualDebtToCover = _debtToCover > maxLiquidation ? maxLiquidation : _debtToCover;

        uint256 collateralPrice = oracleSentinel.getPrice(_vault);
        uint256 collateralToLiquidate = actualDebtToCover.mul(100 + vaultConfigs[_vault].liquidationBonus).div(100).mul(1e18).div(collateralPrice);

        require(collateralToLiquidate <= account.collateralBalances[_vault], "Not enough collateral to liquidate");

        // Transfer debt from liquidator to pool
        require(underlyingAsset.transferFrom(msg.sender, address(this), actualDebtToCover), "Debt transfer failed");

        // Transfer collateral from user to liquidator
        account.collateralBalances[_vault] = account.collateralBalances[_vault].sub(collateralToLiquidate);
        totalCollateralDeposited[_vault] = totalCollateralDeposited[_vault].sub(collateralToLiquidate);
        IERC20(_vault).transfer(msg.sender, collateralToLiquidate);

        // Update user's debt
        account.borrowed = account.borrowed.sub(actualDebtToCover);
        totalBorrowed = totalBorrowed.sub(actualDebtToCover);

        emit Liquidated(msg.sender, _user, _vault, actualDebtToCover, collateralToLiquidate);
    }

    function checkHealth(address _user, address _vault) public view returns (bool) {
        UserAccount storage account = userAccounts[_user];
        uint256 totalCollateralValueInUSD = getTotalCollateralValueInUSD(_user);
        uint256 totalDebtInUSD = getBorrowedPlusInterest(_user);
        return totalCollateralValueInUSD.mul(vaultConfigs[_vault].liquidationThreshold).div(100) >= totalDebtInUSD;
    }

    function getCollateralValueInUSD(address _user, address _vault) public view returns (uint256) {
        uint256 collateralAmount = userAccounts[_user].collateralBalances[_vault];
        uint256 collateralPrice = oracleSentinel.getPrice(_vault);
        return collateralAmount.mul(collateralPrice).div(1e18);
    }

    function getTotalCollateralValueInUSD(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint i = 0; i < vaultConfigs.length; i++) {
            address vault = vaultConfigs[i];
            totalValue = totalValue.add(getCollateralValueInUSD(_user, vault));
        }
        return totalValue;
    }

    function getCurrentLTV(address _user) public view returns (uint256) {
        uint256 totalCollateralValueInUSD = getTotalCollateralValueInUSD(_user);
        if (totalCollateralValueInUSD == 0) return 0;
        uint256 totalDebtInUSD = getBorrowedPlusInterest(_user);
        return totalDebtInUSD.mul(100).div(totalCollateralValueInUSD);
    }

    function getSuppliedPlusYield(address _user) public view returns (uint256) {
        UserAccount storage account = userAccounts[_user];
        uint256 yield = calculateInterest(account.supplied, lastGlobalInterestTimestamp);
        return account.supplied.add(yield);
    }

    function getBorrowedPlusInterest(address _user) public view returns (uint256) {
        UserAccount storage account = userAccounts[_user];
        uint256 interest = calculateInterest(account.borrowed, account.lastInterestTimestamp);
        return account.borrowed.add(interest);
    }

    function getSupplyAPR() public view returns (uint256) {
        return interestRateStrategy.getSupplyRate(totalSupplied, totalBorrowed);
    }

    function getBorrowAPR() public view returns (uint256) {
        return interestRateStrategy.getBorrowRate(totalSupplied, totalBorrowed);
    }

    function setCollateralFactor(address _vault, uint256 _newFactor) external {
        require(msg.sender == address(poolConfigurator), "Only pool configurator can call");
        require(_newFactor <= 100, "Collateral factor must be <= 100");
        vaultConfigs[_vault].collateralFactor = _newFactor;
    }

    function setLiquidationThreshold(address _vault, uint256 _newThreshold) external {
        require(msg.sender == address(poolConfigurator), "Only pool configurator can call");
        require(_newThreshold <= 100, "Liquidation threshold must be <= 100");
        vaultConfigs[_vault].liquidationThreshold = _newThreshold;
    }

    function setLiquidationBonus(address _vault, uint256 _newBonus) external {
        require(msg.sender == address(poolConfigurator), "Only pool configurator can call");
        require(_newBonus <= 50, "Liquidation bonus must be <= 50");
        vaultConfigs[_vault].liquidationBonus = _newBonus;
    }

    function setDepositCap(address _vault, uint256 _newCap) external {
        require(msg.sender == address(poolConfigurator), "Only pool configurator can call");
        vaultConfigs[_vault].depositCap = _newCap;
    }

    function addSupportedVault(address _vault, uint256 _collateralFactor, uint256 _liquidationThreshold, uint256 _liquidationBonus, uint256 _depositCap) external onlyOwner {
        require(vaultConfigs[_vault].collateralFactor == 0, "Vault already supported");
        vaultConfigs[_vault] = VaultConfig({
            collateralFactor: _collateralFactor,
            liquidationThreshold: _liquidationThreshold,
            liquidationBonus: _liquidationBonus,
            depositCap: _depositCap
        });
    }

    function updateGlobalInterest() internal {
        uint256 timeDelta = block.timestamp.sub(lastGlobalInterestTimestamp);
        if (timeDelta > 0) {
            uint256 interestRate = getSupplyAPR();
            uint256 interest = totalSupplied.mul(interestRate).mul(timeDelta).div(365 days).div(100);
            totalSupplied = totalSupplied.add(interest);
            lastGlobalInterestTimestamp = block.timestamp;
        }
    }

    function calculateInterest(uint256 _amount, uint256 _lastTimestamp) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp.sub(_lastTimestamp);
        uint256 interestRate = getBorrowAPR();
        return _amount.mul(interestRate).mul(timeDelta).div(365 days).div(100);
    }
}