// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IPropertyNFT is IERC721, IAccessControl {
    // Enums
    enum PropertyUsage { Flip, Rent, Build }

    // Structs
    struct PropertyDetails {
        PropertyUsage usage;
        address oracle;
        address vault;
        uint256 value;
        address partner;
    }

    // Events
    event PropertyMinted(uint256 indexed tokenId, address indexed partner, PropertyUsage usage, address oracle, address vault);
    event PropertyUsageUpdated(uint256 indexed tokenId, PropertyUsage newUsage);
    event PropertyValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event PartnerApproved(address partner);
    event PartnerRemoved(address partner);
    event PropertyListedForRent(uint256 indexed tokenId, uint256 amount);

    // State Variables
    function PARTNER_ROLE() external view returns (bytes32);
    function properties(uint256 tokenId) external view returns (PropertyDetails memory);
    function approvedPartners(address partner) external view returns (bool);
    function usdcToken() external view returns (address);
    function schemaUid() external view returns (bytes32);
    function oracleSentinel() external view returns (address);

    // Functions
    function approvePartner(address partner) external;
    function updateSchemaUID(bytes32 _schemaUid) external;
    function updateSentinel(address _sentinel) external;
    function removePartner(address partner) external;
    function mintProperty(
        string memory tokenURI,
        PropertyUsage usage,
        uint256 initialValue,
        string calldata vaultName,
        string calldata vaultSymbol
    ) external returns (uint256);
    function leaseProperty(
        uint256 tokenId,
        uint256 rentAmount,
        address rental,
        PropertyUsage usage,
        uint256 initialValue
    ) external returns (uint256);
    function updatePropertyUsage(uint256 tokenId, PropertyUsage newUsage) external;
    function updatePropertyValue(uint256 tokenId, uint256 _value) external;
    function getPropertyDetails(uint256 tokenId) external view returns (PropertyDetails memory);

}