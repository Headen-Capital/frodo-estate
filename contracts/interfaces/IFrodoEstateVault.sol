// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFrodoEstateVault is IERC20 {
    // Events
    event NFTLocked(uint256 tokenId);
    event NFTUnlocked(uint256 tokenId);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensSold(address indexed seller, uint256 amount);
    event InvestmentClosed(uint256 totalValue);

    // State variables
    function nftContract() external view returns (address);
    function oracle() external view returns (address);
    function TOTAL_SHARES() external view returns (uint256);
    function nftTokenId() external view returns (uint256);
    function isNFTLocked() external view returns (bool);
    function partner() external view returns (address);
    function usdcToken() external view returns (address);

    // Functions
    function lockNFT(uint256 _tokenId) external;
    function buyTokens(uint256 amount) external;
    function sellTokens(uint256 amount) external;
    function closeInvestment() external;
    function withdrawShare() external;
    function getTokenValue() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function getTokenPrice(uint256 _amount) external view returns (uint256);
}