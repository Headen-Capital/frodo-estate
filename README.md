# Frodo Estate: A Web3 Fractional Real Estate Application README

Frodo Estate is a pioneering web3 application that revolutionizes the real estate industry by introducing fractional ownership and investment through blockchain technology. This document serves as a comprehensive guide to understanding and utilizing Frodo Estate, including the use of on-chain verifiers for partner authentication, the process of creating vaults with NFTs and oracles, and the benefits of buying vault tokens, borrowing USDT, and investing in real estate through various strategies.

## Introduction to Frodo Estate

Frodo Estate leverages blockchain technology to democratize real estate investment by allowing users to buy fractions of properties, known as vault tokens. These tokens represent ownership stakes in physical properties, providing investors with exposure to real estate markets without the need for large capital investments.

## Use of On-Chain Verifier for Partner Authentication

Frodo Estate employs base on-chain verifier and Fractal KYC service to authenticate partners and ensure the security and integrity of property transactions. This system uses smart contracts to verify the identity and credibility of partners, ensuring that all interactions within the Frodo Estate ecosystem are secure and trustworthy.

### Flow of Frodo Estate Vaults Creation

Creating a vault on Frodo Estate involves several key steps, including the deployment of NFTs and oracles:

1. **NFT Deployment**: Each property listed on Frodo Estate is represented by a unique Non-Fungible Token (NFT). This NFT encapsulates all relevant property details and serves as the basis for fractional ownership.

2. **Oracle Integration**: Oracles are integrated to provide real-time data feeds on property values, market trends, and other relevant metrics. This data is crucial for determining the value of vault tokens and managing investment strategies.

3. **Vault Creation**: Partners can then create vaults and Investors can purchase fractions of the NFTs representing the desired properties. This process involves interacting with smart contracts to allocate ownership percentages according to the number of tokens purchased.

## How to Buy Vault Tokens from Deployed Vaults

Buying vault tokens from deployed vaults is a straightforward process:

1. **Connect Wallet**: Ensure your wallet is connected to the Frodo Estate platform.
2. **Select Property**: Browse the list of available properties and select the one you wish to invest in.
3. **Purchase Tokens**: Specify the fraction of the property you wish to own and proceed with the purchase. Your wallet will be debited accordingly, and you will receive vault tokens in return.

### Why Invest in a Property by Buying Fractions?

Investing in a property by buying fractions of it through Frodo Estate offers several advantages:

- **Accessibility**: Without the need for large amounts of capital, anyone can gain exposure to real estate investments.
- **Diversification**: Investing in fractions of multiple properties allows for diversification across different locations and asset types.
- **Transparency**: Blockchain technology ensures that all transactions are transparent and verifiable.

## Use of Vault Tokens for Collateral to Borrow USDT

Vault tokens can be used as collateral to borrow USDT, providing an additional incentive to invest in real estate:

1. **Collateralize Tokens**: List your vault tokens as collateral in the borrowing section of the Frodo Estate platform.
2. **Request USDT Loan**: Specify the amount of USDT you wish to borrow against your collateral.
3. **Confirmation**: Upon approval, the requested USDT will be credited to your wallet, allowing you to reinvest in more properties or use the funds for other purposes.

## Investment of Borrowed Tokens in Investment Strategies

Investing borrowed tokens in investment strategies is another way to generate yield while maintaining exposure to real estate:

1. **Strategic Allocation**: Allocate a portion of your borrowed tokens to predefined investment strategies that align with your risk tolerance and investment goals.
2. **Automated Management**: Let the platform manage your investments automatically, optimizing for returns based on current market conditions.
3. **Manual Adjustment**: Alternatively, manually adjust your allocations to capitalize on specific market opportunities.

## Conclusion

Frodo Estate represents a significant leap forward in the real estate investment space, making it accessible and profitable for a wider audience. By leveraging blockchain technology, NFTs, oracles, and innovative financial instruments, Frodo Estate opens the door to fractional ownership of real estate, offering unprecedented opportunities for growth and diversification.

## Technical Overview

Frodo Estate's technical framework is underpinned by a series of smart contracts that collectively enable its innovative approach to fractional real estate investment, leveraging blockchain technology for security, transparency, and efficiency. This overview explores the key contracts that form the backbone of Frodo Estate, detailing their purpose and functionality within the ecosystem.

## Core Contracts

### FrodoEstateVault.sol

The `FrodoEstateVault.sol` contract is central to the operation of Frodo Estate, managing the creation and lifecycle of property vaults. It integrates with NFTs to represent property ownership and utilizes oracles for real-time valuation. Key features include:

- **NFT Locking**: Securely locks NFTs representing properties within the contract, establishing a direct link between digital and physical assets.
- **Token Operations**: Handles the minting and burning of tokens, reflecting ownership fractions of the underlying property.
- **Collateralization and Loans**: Allows tokens to be used as collateral for borrowing USDT, expanding investment opportunities.

### PropertyNFT.sol

`PropertyNFT.sol` introduces NFTs into the ecosystem, where each token represents a unique property. It supports:

- **Minting NFTs**: Creates NFTs for each property listed on the platform, encapsulating property details and ownership rights.
- **Ownership Management**: Manages transfers and ownership validations, ensuring secure and transparent property transactions.

### PropertyOracle.sol

`PropertyOracle.sol` acts as a bridge between on-chain and off-chain data, providing real-time property valuations. It's responsible for:

- **Valuation Updates**: Regularly updates property values based on external data sources, influencing the value of associated tokens and collateral calculations.
- **Data Integrity**: Ensures data accuracy and reliability through a controlled access pattern.

### MicroLendingPool.sol

`MicroLendingPool.sol` facilitates the lending aspect of Frodo Estate, allowing users to leverage their assets for loans. It encompasses:

- **Collateral Management**: Accepts vault tokens as collateral for USDT loans, managing risk through over-collateralization and liquidation thresholds.
- **Interest Rate Models**: Implements dynamic interest rates based on supply and demand, ensuring sustainable lending practices.

### YieldStrategyManager.sol

`YieldStrategyManager.sol` optimizes token investments across various DeFi protocols to maximize returns. It features:

- **Strategy Allocation**: Distributes investments across Aave, Morpho, and Uniswap, balancing risk and reward.
- **Harvesting Yields**: Automates the compounding of earned interest, enhancing investment efficiency.

### AaveYieldStrategy.sol

`AaveYieldStrategy.sol` integrates with Aave for lending operations, offering:

- **Interest Earnings**: Deposits assets into Aave's lending market, earning interest based on current rates.
- **Withdrawals**: Allows for the withdrawal of assets, ensuring liquidity for investors.

## Security Considerations

Security is integral to Frodo Estate, with contracts is being developed following best practices:

- **Audit and Verification**: Underwent thorough audits and testing, minimizing vulnerabilities.
- **Access Control**: Implements strict access controls, preventing unauthorized actions.
- **Upgradeability**: Designed with mechanisms for safe upgrades, maintaining flexibility without compromising trustlessness.
- **Testing**

## Deployments

## Base Goerli

- PropertyNFT: 0x7d5524041A6630352C761ddBB360226e0e6140EF
- YieldStrategyManager: 0x9B45705f8dd61785fa00F63DeB09910eae89f5AF
- MicroLendingPool: 0x9B9c98f8D04FeA09e50953187F93b505D2539BE4
- PoolConfigurator:
- CollateralOracleSentinel: 0x393d1c765bFf6402CFaEB83D6e091EF6993414B1
- LP Token: 0xf97aea816b1eB11BcD4A58A27512a2240aE245F8
- Debt Token: 0xa332431d2375c3Ac696599E7f29BDF446122bcC9
