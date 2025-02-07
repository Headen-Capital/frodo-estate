// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PropertyOracle.sol";

contract FrodoEstateVault is ERC20, ReentrancyGuard {
    IERC721 public nftContract;
    PropertyOracle public oracle;
    uint256 public constant TOTAL_SHARES = 10000 * 1e18;
    uint256 public nftTokenId;
    bool public isNFTLocked;
    address public partner;

    IERC20 public usdcToken;

    event NFTLocked(uint256 tokenId);
    event NFTUnlocked(uint256 tokenId);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensSold(address indexed seller, uint256 amount);
    event InvestmentClosed(uint256 totalValue);

    constructor(address _nftContract, address _oracle, address _usdcToken, address _partner, string memory name, string memory symbol) ERC20(name, symbol) {
        nftContract = IERC721(_nftContract);
        oracle = PropertyOracle(_oracle);
        usdcToken = IERC20(_usdcToken);
        partner = _partner;
    }

    function lockNFT(uint256 _tokenId) external {
        require(msg.sender == partner, "Only partner can lock NFT");
        require(!isNFTLocked, "NFT already locked");
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        nftTokenId = _tokenId;
        isNFTLocked = true;
        _mint(address(this), TOTAL_SHARES);
        emit NFTLocked(_tokenId);
    }

    function buyTokens(uint256 amount) external nonReentrant {
        require(isNFTLocked, "No NFT locked");
        require(amount <= balanceOf(address(this)), "Not enough tokens available");
        
        uint256 price = (amount * oracle.getValue(address(this))) / TOTAL_SHARES;
        require(usdcToken.transferFrom(msg.sender, address(this), price), "USDT transfer failed");

        _transfer(address(this), msg.sender, amount);
        emit TokensPurchased(msg.sender, amount);
    }

    function sellTokens(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient tokens");

        uint256 price = (amount * oracle.getValue(address(this))) / TOTAL_SHARES;
        require(price <= usdcToken.balanceOf(address(this)), "Not enough tokens available");
        require(usdcToken.transfer(msg.sender, price), "USDT transfer failed");

        _transfer(msg.sender, address(this), amount);
        emit TokensSold(msg.sender, amount);
    }

    function closeInvestment() external nonReentrant {
        require(msg.sender == partner, "Only partner can close investment");
        require(isNFTLocked, "No NFT locked");
        
        uint256 totalValue = oracle.getValue(address(this));
        require(usdcToken.transferFrom(partner, address(this), totalValue), "USDT transfer failed");

        isNFTLocked = false;
        nftContract.transferFrom(address(this), partner, nftTokenId);

        // burn and refund if any shares is left
        if(balanceOf(address(this)) > 0){
            uint remainingBalance = balanceOf(address(this));
            _burn(address(this), remainingBalance);
            require(usdcToken.transfer(partner, remainingBalance * totalValue / TOTAL_SHARES), "USDT transfer failed");
        }

        emit NFTUnlocked(nftTokenId);
        emit InvestmentClosed(totalValue);
    }

    function withdrawShare() external nonReentrant {
        require(!isNFTLocked, "Investment not closed yet");
        uint256 share = balanceOf(msg.sender);
        require(share > 0, "No tokens to withdraw");
        
        uint256 totalValue = usdcToken.balanceOf(address(this));
        uint256 userShare = (share * totalValue) / TOTAL_SHARES;

        _burn(msg.sender, share);
        require(usdcToken.transfer(msg.sender, userShare), "USDT transfer failed");
    }

    function getTokenValue() external view returns (uint256) {
        return oracle.getValue(address(this)) / TOTAL_SHARES;
    }

    function getTotalShares() external view returns (uint256) {
        return TOTAL_SHARES;
    }

    function getTokenPrice(uint256 _amount) external view returns (uint256) {
        return _amount * oracle.getValue(address(this)) / TOTAL_SHARES;
    }
}