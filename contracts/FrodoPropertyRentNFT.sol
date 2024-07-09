
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PropertyNFT.sol";

contract PropertyRentNFT is ERC721URIStorage, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;
    
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");

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

    mapping(uint256 => RentalDetails) public rentals;
    mapping(uint256 => uint256) public propertyToRentalNFT;
    mapping(uint256 => PendingRentChange) public pendingRentChanges;
    mapping(uint256 => RentalApplication[]) public rentalApplications;

    PropertyNFT public immutable propertyNFTContract;
    IERC20 public immutable usdcToken;
    uint256 public constant RENT_PERIOD = 30 days;
    uint256 public constant EVICTION_NOTICE_PERIOD = 120 days;

    event RentalListed(uint256 indexed propertyId, uint256 indexed rentalNFTId, uint256 rentAmount);
    event RentalApplicationSubmitted(uint256 indexed rentalNFTId, address indexed applicant);
    event RentalApplicationApproved(uint256 indexed rentalNFTId, address indexed renter);
    event RentalStarted(uint256 indexed rentalNFTId, address indexed renter);
    event RentPaid(uint256 indexed rentalNFTId, uint256 amount);
    event RentalEnded(uint256 indexed rentalNFTId);
    event RentChangeScheduled(uint256 indexed rentalNFTId, uint256 newRentAmount, uint256 effectiveDate);
    event EvictionNoticeIssued(uint256 indexed rentalNFTId, uint256 effectiveDate);

    constructor(address _propertyNFTContract, address owner, address _usdcToken) ERC721("Frodo Estate Rental", "FER") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PARTNER_ROLE, msg.sender);
        _setupRole(PARTNER_ROLE, owner);
        propertyNFTContract = PropertyNFT(_propertyNFTContract);
        usdcToken = IERC20(_usdcToken);
    }

    function listPropertyForRent(uint256 propertyId, uint256 rentAmount, address partner) external onlyRole(PARTNER_ROLE) {
        require(propertyToRentalNFT[propertyId] == 0, "Property already listed");
        require(propertyNFTContract.ownerOf(propertyId) == msg.sender, "Not the property owner");
        
        uint256 newRentalNFTId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(address(this), newRentalNFTId);

        rentals[newRentalNFTId] = RentalDetails({
            partner: partner,
            propertyId: propertyId,
            renter: address(0),
            rentAmount: rentAmount,
            lastPaymentDate: 0,
            nextPaymentDate: 0,
            isActive: false,
            evictionNoticeDate: 0
        });

        propertyToRentalNFT[propertyId] = newRentalNFTId;

        propertyNFTContract.transferFrom(msg.sender, address(this), propertyId);

        emit RentalListed(propertyId, newRentalNFTId, rentAmount);
    }

    function requestRental(uint256 rentalNFTId) external {
        require(!rentals[rentalNFTId].isActive, "Property already rented");
        rentalApplications[rentalNFTId].push(RentalApplication({
            applicant: msg.sender,
            approved: false
        }));
        emit RentalApplicationSubmitted(rentalNFTId, msg.sender);
    }

    function acceptRental(uint256 rentalNFTId, address chosenRenter) external {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(msg.sender == rental.partner, "Not the property partner");
        require(!rental.isActive, "Rental already active");
        require(rental.renter == address(0), "Renter already assigned");

        bool applicantFound = false;
        for (uint i = 0; i < rentalApplications[rentalNFTId].length; i++) {
            if (rentalApplications[rentalNFTId][i].applicant == chosenRenter) {
                rentalApplications[rentalNFTId][i].approved = true;
                applicantFound = true;
                break;
            }
        }
        require(applicantFound, "Chosen renter did not apply");

        rental.renter = chosenRenter;
        rental.isActive = true;
        rental.lastPaymentDate = block.timestamp;
        rental.nextPaymentDate = block.timestamp + RENT_PERIOD;

        usdcToken.safeTransferFrom(chosenRenter, address(this), rental.rentAmount);
        _transfer(address(this), chosenRenter, rentalNFTId);

        emit RentalApplicationApproved(rentalNFTId, chosenRenter);
        emit RentalStarted(rentalNFTId, chosenRenter);
    }

    function payRent(uint256 rentalNFTId) external nonReentrant {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(rental.isActive, "Rental not active");
        require(msg.sender == rental.renter, "Not the renter");
        require(block.timestamp >= rental.nextPaymentDate, "Rent not due yet");

        _applyPendingRentChange(rentalNFTId);
        usdcToken.safeTransferFrom(msg.sender, address(this), rental.rentAmount);

        rental.lastPaymentDate = block.timestamp;
        rental.nextPaymentDate = block.timestamp + RENT_PERIOD;


        emit RentPaid(rentalNFTId, rental.rentAmount);
    }

    function endRental(uint256 rentalNFTId) external {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(rental.isActive, "Rental not active");
        require(msg.sender == rental.partner, "Not the property partner");
        require(block.timestamp > rental.nextPaymentDate + RENT_PERIOD, "Rent not overdue for two periods");

        _endRental(rentalNFTId);
    }

    function evictRenter(uint256 rentalNFTId) external {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(msg.sender == rental.partner, "Not the property partner");
        require(rental.isActive, "Rental not active");
        
        if (rental.evictionNoticeDate == 0) {
            rental.evictionNoticeDate = block.timestamp + EVICTION_NOTICE_PERIOD;
            emit EvictionNoticeIssued(rentalNFTId, rental.evictionNoticeDate);
        } else if (block.timestamp >= rental.evictionNoticeDate) {
            _endRental(rentalNFTId);
        }
    }

    function _endRental(uint256 rentalNFTId) internal {
        RentalDetails storage rental = rentals[rentalNFTId];
        address oldRenter = rental.renter;
        rental.isActive = false;
        rental.renter = address(0);
        rental.evictionNoticeDate = 0;

        _transfer(oldRenter, address(this), rentalNFTId);

        if (!_hasActiveRentals(rental.propertyId)) {
            propertyNFTContract.transferFrom(address(this), rental.partner, rental.propertyId);
        }

        emit RentalEnded(rentalNFTId);
    }

    function _hasActiveRentals(uint256 propertyId) internal view returns (bool) {
        uint256 rentalNFTId = propertyToRentalNFT[propertyId];
        return rentals[rentalNFTId].isActive;
    }

    function scheduleRentChange(uint256 rentalNFTId, uint256 newRentAmount) external {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(msg.sender == rental.partner, "Not the property partner");
        require(rental.isActive, "Rental not active");
        
        uint256 effectiveDate = rental.nextPaymentDate + RENT_PERIOD;
        pendingRentChanges[rentalNFTId] = PendingRentChange({
            newRentAmount: newRentAmount,
            effectiveDate: effectiveDate
        });
        
        emit RentChangeScheduled(rentalNFTId, newRentAmount, effectiveDate);
    }


    function _applyPendingRentChange(uint256 rentalNFTId) internal {
        RentalDetails storage rental = rentals[rentalNFTId];
        PendingRentChange storage pendingChange = pendingRentChanges[rentalNFTId];
        
        if (pendingChange.newRentAmount > 0 && block.timestamp >= pendingChange.effectiveDate) {
            rental.rentAmount = pendingChange.newRentAmount;
            delete pendingRentChanges[rentalNFTId];
        }
    }

    function withdrawRent(uint256 rentalNFTId) external {
        RentalDetails storage rental = rentals[rentalNFTId];
        require(msg.sender == rental.partner, "Not the property partner");
        
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No rent to withdraw");
        
        usdcToken.safeTransfer(rental.partner, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}