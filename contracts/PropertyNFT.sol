// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@coinbase/verifications/abstracts/AttestationAccessControl.sol";
import {Attestation, AttestationVerifier} from "@coinbase/verifications/libraries/AttestationVerifier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./FrodoEstateVault.sol";
import "./PropertyOracle.sol";

contract PropertyNFT is ERC721URIStorage, AccessControl, AttestationAccessControl, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");

    enum PropertyUsage { Flip, Rent, Build }

    struct PropertyDetails {
        PropertyUsage usage;
        address oracle;
        address vault;
        uint256 value;
        address partner;
    }

    mapping(uint256 => PropertyDetails) public properties;
    mapping(address => bool) public approvedPartners;

    address public usdcToken;
    bytes32 public schemaUid;

    event PropertyMinted(uint256 indexed tokenId, address indexed partner, PropertyUsage usage, address oracle, address vault);
    event PropertyUsageUpdated(uint256 indexed tokenId, PropertyUsage newUsage);
    event PropertyValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event PartnerApproved(address partner);
    event PartnerRemoved(address partner);

    constructor(address _usdcToken, address owner) ERC721("Frodo Estate Property", "FEP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        usdcToken = _usdcToken;
        schemaUid = 0x2f34a2ffe5f87b2f45fbc7c784896b768d77261e2f24f77341ae43751c765a69;
        transferOwnership(owner);
    }

    function approvePartner(address partner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _verifyAttestation(partner);
        approvedPartners[partner] = true;
        grantRole(PARTNER_ROLE, partner);
        emit PartnerApproved(partner);
    }

    function updateSchemaUID(bytes32 _schemaUid) external onlyRole(DEFAULT_ADMIN_ROLE) {
       schemaUid =_schemaUid;
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
        _verifyAttestation(msg.sender);

        // Create Oracle
        PropertyOracle newOracle = new PropertyOracle(owner());
        newOracle.grantRole(newOracle.UPDATER_ROLE(), msg.sender);
        

        // Create Vault
        FrodoEstateVault newVault = new FrodoEstateVault(address(this), address(newOracle), usdcToken, msg.sender);
        newOracle.updateValue(address(newVault), initialValue);
        require(_isApprovedOrOwner(address(newVault), newTokenId),"Approve the vault contract before minting Property");
        newVault.lockNFT(newTokenId);

        properties[newTokenId] = PropertyDetails({
            usage: usage,
            oracle: address(newOracle),
            vault: address(newVault),
            value: initialValue,
            partner: msg.sender
        });

        emit PropertyMinted(newTokenId, msg.sender, usage, address(newOracle), address(newVault));

        return newTokenId;
    }

    function updatePropertyUsage(uint256 tokenId, PropertyUsage newUsage) external onlyRole(PARTNER_ROLE) {
        require(properties[tokenId].partner == msg.sender, "Caller is not owner nor approved");
        properties[tokenId].usage = newUsage;
        emit PropertyUsageUpdated(tokenId, newUsage);
    }

    function updatePropertyValue(uint256 tokenId,  uint256 _value) external onlyRole(PARTNER_ROLE) {
        require(properties[tokenId].partner == msg.sender, "Caller is not owner nor approved");
        PropertyDetails memory property = properties[tokenId];
        PropertyOracle(property.oracle).updateValue(property.vault, _value);
        emit PropertyValueUpdated(tokenId, _value);
    }

    function getPropertyDetails(uint256 tokenId) external view returns (PropertyDetails memory) {
        return properties[tokenId];
    }

    // Override required functions
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _verifyAttestation(address user) internal {
        Attestation memory attestation = _getAttestation(user, schemaUid);
        AttestationVerifier.verifyAttestation(attestation,user, schemaUid);
    }
}