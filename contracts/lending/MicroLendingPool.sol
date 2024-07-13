// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {InterestRateStrategy} from "./InterestRateStrategy.sol";
import {CollateralOracleSentinel} from "./OracleSentinel.sol";
import {LPToken} from "./LPToken.sol";
import {DebtToken} from "./DebtToken.sol";
import {PoolConfigurator} from "./MicroLendingPoolConfigurator.sol";

contract LendingPool is ReentrancyGuard, Ownable, AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    IERC20 public immutable underlyingAsset;
    InterestRateStrategy public interestRateStrategy;
    CollateralOracleSentinel public oracleSentinel;
    LPToken public lpToken;
    DebtToken public debtToken;
    PoolConfigurator public poolConfigurator;
    address[] public vaults;

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
    uint256 public closeFactor; // New close factor for liquidations

    event Supplied(address indexed user, uint256 amount);
    event Borrowed(address indexed user, address vault, uint256 amount);
    event Repaid(address indexed user, uint256 amount, uint256 interest);
    event Withdrawn(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, address indexed vault, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed vault, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed user, address indexed vault, uint256 debtRepaid, uint256 collateralLiquidated);
    event InterestAccrued(uint256 supplyInterest, uint256 borrowInterest);

    constructor(
        address _underlyingAsset,
        address _interestRateStrategy,
        address _oracleSentinel,
        address _lpToken,
        address _debtToken,
        uint256 _closeFactor,
        address _owner,
        address _configurator
    ) {
        underlyingAsset = IERC20(_underlyingAsset);
        interestRateStrategy = InterestRateStrategy(_interestRateStrategy);
        oracleSentinel = CollateralOracleSentinel(_oracleSentinel);
        lpToken = LPToken(_lpToken);
        debtToken = DebtToken(_debtToken);
        lastGlobalInterestTimestamp = block.timestamp;
        closeFactor = _closeFactor;
        transferOwnership(_owner);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONFIGURATOR_ROLE, msg.sender);
        _setupRole(CONFIGURATOR_ROLE, _configurator);
    }

    function setPoolConfigurator(address _poolConfigurator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        poolConfigurator = PoolConfigurator(_poolConfigurator);
    }

    function setTokens(address _lpToken, address _debtToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lpToken = LPToken(_lpToken);
        debtToken = DebtToken(_debtToken);
    }

    function setIRStrategy(address _interestRateStrategy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        interestRateStrategy = InterestRateStrategy(_interestRateStrategy);
    }

    function supply(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than 0");
        require(underlyingAsset.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        updateGlobalInterest();
        UserAccount storage account = userAccounts[msg.sender];
        account.supplied = account.supplied.add(_amount);
        totalSupplied = totalSupplied.add(_amount);

        lpToken.mint(msg.sender, _amount);

        emit Supplied(msg.sender, _amount);
    }

    function borrow(address _vault, uint256 _amount) external nonReentrant whenNotPaused {
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

    function repay(uint256 _amount) external nonReentrant whenNotPaused {
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

    function withdraw(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than 0");
        updateGlobalInterest();
        
        UserAccount storage account = userAccounts[msg.sender];
        require(account.supplied >= _amount, "Insufficient balance");
        require(totalSupplied.sub(totalBorrowed) >= _amount, "Not enough liquidity");

        account.supplied = account.supplied.sub(_amount);
        totalSupplied = totalSupplied.sub(_amount);

        require(checkHealth(msg.sender), "Withdrawal would make position unhealthy");

        lpToken.burn(msg.sender, _amount);
        require(underlyingAsset.transfer(msg.sender, _amount), "Transfer failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function depositCollateral(address _vault, uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be greater than 0");
        require(vaultConfigs[_vault].collateralFactor > 0, "Vault not supported");
        require(totalCollateralDeposited[_vault].add(_amount) <= vaultConfigs[_vault].depositCap, "Deposit cap reached");

        IERC20(_vault).transferFrom(msg.sender, address(this), _amount);
        
        UserAccount storage account = userAccounts[msg.sender];
        account.collateralBalances[_vault] = account.collateralBalances[_vault].add(_amount);
        totalCollateralDeposited[_vault] = totalCollateralDeposited[_vault].add(_amount);

        emit CollateralDeposited(msg.sender, _vault, _amount);
    }

    function withdrawCollateral(address _vault, uint256 _amount) external nonReentrant whenNotPaused {
        UserAccount storage account = userAccounts[msg.sender];
        require(account.collateralBalances[_vault] >= _amount, "Insufficient collateral balance");
        
        account.collateralBalances[_vault] = account.collateralBalances[_vault].sub(_amount);
        totalCollateralDeposited[_vault] = totalCollateralDeposited[_vault].sub(_amount);

        require(checkHealth(msg.sender), "Withdrawal would make position unhealthy");

        IERC20(_vault).transfer(msg.sender, _amount);

        emit CollateralWithdrawn(msg.sender, _vault, _amount);
    }

    function liquidate(address _user, address _vault, uint256 _debtToCover) external nonReentrant whenNotPaused {
        require(_debtToCover > 0, "Debt to cover must be greater than 0");
        require(!checkHealth(_user), "User position is healthy");

        UserAccount storage account = userAccounts[_user];
        uint256 userTotalDebt = getBorrowedPlusInterest(_user);
        uint256 maxLiquidation = userTotalDebt.mul(closeFactor).div(100);
        uint256 actualDebtToCover = _debtToCover > maxLiquidation ? maxLiquidation : _debtToCover;
        uint256 collateralToLiquidate = actualDebtToCover.mul(100 + vaultConfigs[_vault].liquidationBonus).div(100).mul(1e18).div(oracleSentinel.getPrice(_vault));

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

        // Burn debt tokens
        debtToken.burn(_user, actualDebtToCover);

        emit Liquidated(msg.sender, _user, _vault, actualDebtToCover, collateralToLiquidate);
    }

    function checkHealth(address _user) public view returns (bool) {
        uint256 totalCollateralValueInUSD = getTotalCollateralValueInUSD(_user);
        uint256 totalDebtInUSD = getBorrowedPlusInterest(_user);
        return totalCollateralValueInUSD.mul(getWeightedLiquidationThreshold(_user)).div(100) >= totalDebtInUSD;
    }

    function checkHealth(address _user, address _vault) external view returns (bool) {
        uint256 totalCollateralValueInUSD = getCollateralValueInUSD(_user, _vault);
        uint256 totalDebtInUSD = getBorrowedPlusInterest(_user);
        return totalCollateralValueInUSD.mul(vaultConfigs[_vault].liquidationThreshold).div(100) >= totalDebtInUSD;
    }

    function getWeightedLiquidationThreshold(address _user) public view returns (uint256) {
        uint256 totalCollateralValueInUSD = 0;
        uint256 weightedThreshold = 0;
        uint256 vaultsLength = vaults.length;
        for (uint256 i = 0; i < vaultsLength; i++) {
            address vault = vaults[i];
            uint256 collateralValue = getCollateralValueInUSD(_user, vault);
            totalCollateralValueInUSD = totalCollateralValueInUSD.add(collateralValue);
            weightedThreshold = weightedThreshold.add(collateralValue.mul(vaultConfigs[vault].liquidationThreshold));
        }
        return totalCollateralValueInUSD > 0 ? weightedThreshold.div(totalCollateralValueInUSD) : 0;
    }

    function getCollateralValueInUSD(address _user, address _vault) public view returns (uint256) {
        uint256 collateralAmount = userAccounts[_user].collateralBalances[_vault];
        uint256 collateralPrice = oracleSentinel.getPrice(_vault);
        return collateralAmount.mul(collateralPrice).div(1e18);
    }

    function getTotalCollateralValueInUSD(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        uint256 vaultsLength = vaults.length;
        for (uint256 i = 0; i < vaultsLength; i++) {
            address vault = vaults[i];
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
        uint256 yield = calculateSupplyInterest(account.supplied, lastGlobalInterestTimestamp);
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

    function setCollateralFactor(address _vault, uint256 _newFactor) external onlyRole(CONFIGURATOR_ROLE) {
        require(_newFactor <= 100, "Collateral factor must be <= 100");
        vaultConfigs[_vault].collateralFactor = _newFactor;
    }

    function setLiquidationThreshold(address _vault, uint256 _newThreshold) external onlyRole(CONFIGURATOR_ROLE) {
        require(_newThreshold <= 100, "Liquidation threshold must be <= 100");
        vaultConfigs[_vault].liquidationThreshold = _newThreshold;
        }

    function setLiquidationBonus(address _vault, uint256 _newBonus) external onlyRole(CONFIGURATOR_ROLE) {
        require(_newBonus <= 50, "Liquidation bonus must be <= 50");
        vaultConfigs[_vault].liquidationBonus = _newBonus;
    }

    function setDepositCap(address _vault, uint256 _newCap) external onlyRole(CONFIGURATOR_ROLE) {
        vaultConfigs[_vault].depositCap = _newCap;
    }

    function setCloseFactor(uint256 _newCloseFactor) external onlyRole(CONFIGURATOR_ROLE) {
        require(_newCloseFactor > 0 && _newCloseFactor <= 100, "Close factor must be between 1 and 100");
        closeFactor = _newCloseFactor;
    }

    function addSupportedVault(address _vault, uint256 _collateralFactor, uint256 _liquidationThreshold, uint256 _liquidationBonus, uint256 _depositCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vaultConfigs[_vault].collateralFactor == 0, "Vault already supported");
        vaults.push(_vault);
        vaultConfigs[_vault] = VaultConfig({
            collateralFactor: _collateralFactor,
            liquidationThreshold: _liquidationThreshold,
            liquidationBonus: _liquidationBonus,
            depositCap: _depositCap
        });
    }

    function updateGlobalInterest() internal {
        uint256 timeDelta = block.timestamp.sub(lastGlobalInterestTimestamp);
        // update rate here
        interestRateStrategy.updateInterestRateModel(address(this));
        if (timeDelta > 0) {
            uint256 supplyInterestRate = getSupplyAPR();
            uint256 borrowInterestRate = getBorrowAPR();
            uint256 supplyInterest = totalSupplied.mul(supplyInterestRate).mul(timeDelta).div(365 days).div(100);
            uint256 borrowInterest = totalBorrowed.mul(borrowInterestRate).mul(timeDelta).div(365 days).div(100);
            totalSupplied = totalSupplied.add(supplyInterest);
            totalBorrowed = totalBorrowed.add(borrowInterest);
            lastGlobalInterestTimestamp = block.timestamp;
            emit InterestAccrued(supplyInterest, borrowInterest);
        }
    }

    function calculateInterest(uint256 _amount, uint256 _lastTimestamp) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp.sub(_lastTimestamp);
        uint256 interestRate = getBorrowAPR();
        return _amount.mul(interestRate).mul(timeDelta).div(365 days).div(100);
    }

    function calculateSupplyInterest(uint256 _amount, uint256 _lastTimestamp) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp.sub(_lastTimestamp);
        uint256 interestRate = getSupplyAPR();
        return _amount.mul(interestRate).mul(timeDelta).div(365 days).div(100);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Flash loan functionality
    function flashLoan(address receiver, uint256 amount, bytes calldata params) external nonReentrant whenNotPaused {
        require(amount <= totalSupplied.sub(totalBorrowed), "Not enough liquidity");
        
        uint256 fee = amount.mul(50).div(10000); // 0.5% fee
        uint256 amountToRepay = amount.add(fee);

        require(underlyingAsset.transfer(receiver, amount), "Transfer failed");

        // Call the receiver's function
        (bool success, ) = receiver.call(abi.encodeWithSignature("executeOperation(uint256,uint256,address,address,bytes)", amount, fee, address(this),msg.sender, params));
        require(success, "Flash loan execution failed");

        // Repay the flash loan
        require(underlyingAsset.transferFrom(receiver, address(this), amountToRepay), "Flash loan repayment failed");

        // Update total supplied with the fee
        totalSupplied = totalSupplied.add(fee);
    }

    // View function to get all supported vaults
    function getSupportedVaults() external view returns (address[] memory) {
        return vaults;
    }

    // View function to get vault config
    function getVaultConfig(address _vault) external view returns (VaultConfig memory) {
        return vaultConfigs[_vault];
    }

    // Internal function to check if a vault is supported
    function isVaultSupported(address _vault) internal view returns (bool) {
        return vaultConfigs[_vault].collateralFactor > 0;
    }

    // Function to update the oracle
    function updateOracle(address _newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracleSentinel = CollateralOracleSentinel(_newOracle);
    }
}