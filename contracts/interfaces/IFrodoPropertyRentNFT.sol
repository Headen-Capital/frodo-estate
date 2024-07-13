// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IPropertyRentNFT is IERC721, IAccessControl {
    // Structs
    struct RentalDetails {
        address partner;
        uint256 propertyId;
        address renter;
        uint256 rentAmount;
        uint256 lastPaymentDate;
        uint256 nextPaymentDate;
        bool isActive;
        uint256 evictionNoticeDate;
    }

    struct RentalApplication {
        address applicant;
        bool approved;
    }

    struct PendingRentChange {
        uint256 newRentAmount;
        uint256 effectiveDate;
    }

    // Events
    event RentalListed(uint256 indexed propertyId, uint256 indexed rentalNFTId, uint256 rentAmount);
    event RentalApplicationSubmitted(uint256 indexed rentalNFTId, address indexed applicant);
    event RentalApplicationApproved(uint256 indexed rentalNFTId, address indexed renter);
    event RentalStarted(uint256 indexed rentalNFTId, address indexed renter);
    event RentPaid(uint256 indexed rentalNFTId, uint256 amount);
    event RentalEnded(uint256 indexed rentalNFTId);
    event RentChangeScheduled(uint256 indexed rentalNFTId, uint256 newRentAmount, uint256 effectiveDate);
    event EvictionNoticeIssued(uint256 indexed rentalNFTId, uint256 effectiveDate);

    // State Variables
    function PARTNER_ROLE() external view returns (bytes32);
    function propertyNFTContract() external view returns (address);
    function usdcToken() external view returns (address);
    function RENT_PERIOD() external view returns (uint256);
    function EVICTION_NOTICE_PERIOD() external view returns (uint256);

    // Functions
    function rentals(uint256 rentalNFTId) external view returns (RentalDetails memory);
    function propertyToRentalNFT(uint256 propertyId) external view returns (uint256);
    function pendingRentChanges(uint256 rentalNFTId) external view returns (PendingRentChange memory);
    function rentalApplications(uint256 rentalNFTId, uint256 index) external view returns (RentalApplication memory);

    function listPropertyForRent(uint256 propertyId, uint256 rentAmount, address partner) external;
    function requestRental(uint256 rentalNFTId) external;
    function acceptRental(uint256 rentalNFTId, address chosenRenter) external;
    function payRent(uint256 rentalNFTId) external;
    function endRental(uint256 rentalNFTId) external;
    function evictRenter(uint256 rentalNFTId) external;
    function scheduleRentChange(uint256 rentalNFTId, uint256 newRentAmount) external;
    function withdrawRent(uint256 rentalNFTId) external;

}