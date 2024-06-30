// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./FrodoEstateVault.sol";
import "./PropertyOracle.sol";

contract FPropertyNFT is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");

    enum PropertyUsage { Flip, Rent, Build }

    struct PropertyDetails {
        PropertyUsage usage;
        address oracle;
        address vault;
        uint256 value;
    }

    mapping(uint256 => PropertyDetails) public properties;
    mapping(address => bool) public approvedPartners;

    address public usdcToken;

    event PropertyMinted(uint256 indexed tokenId, address indexed partner, PropertyUsage usage, address oracle, address vault);
    event PropertyUsageUpdated(uint256 indexed tokenId, PropertyUsage newUsage);
    event PropertyValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event PartnerApproved(address partner);
    event PartnerRemoved(address partner);

    constructor(address _usdcToken) ERC721("Frodo Estate Property", "FEP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        usdcToken = _usdcToken;
    }

    function approvePartner(address partner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approvedPartners[partner] = true;
        grantRole(PARTNER_ROLE, partner);
        emit PartnerApproved(partner);
    }

    function removePartner(address partner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approvedPartners[partner] = false;
        revokeRole(PARTNER_ROLE, partner);
        emit PartnerRemoved(partner);
    }

    function mintProperty(
        string memory tokenURI,
        PropertyUsage usage,
        uint256 initialValue
    ) external onlyRole(PARTNER_ROLE) returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // Create Oracle
        PropertyOracle newOracle = new PropertyOracle();
        newOracle.grantRole(newOracle.UPDATER_ROLE(), msg.sender);
        

        // Create Vault
        FrodoEstateVault newVault = new FrodoEstateVault(address(this), address(newOracle), usdcToken, msg.sender);
        newOracle.updateValue(address(newVault), initialValue);

        properties[newTokenId] = PropertyDetails({
            usage: usage,
            oracle: address(newOracle),
            vault: address(newVault),
            value: initialValue
        });

        emit PropertyMinted(newTokenId, msg.sender, usage, address(newOracle), address(newVault));

        return newTokenId;
    }

    function updatePropertyUsage(uint256 tokenId, PropertyUsage newUsage) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        properties[tokenId].usage = newUsage;
        emit PropertyUsageUpdated(tokenId, newUsage);
    }

    function getPropertyDetails(uint256 tokenId) external view returns (PropertyDetails memory) {
        return properties[tokenId];
    }

    // Override required functions
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}