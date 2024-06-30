// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract PropertyOracle is AccessControl {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    uint256 values;
    uint256 timestamps;

    event ValueUpdated(address indexed vault, uint256 newValue, uint256 timestamp);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
    }

    function updateValue(address vault, uint256 _value) external onlyRole(UPDATER_ROLE) { // in usd
        values = _value;
        timestamps = block.timestamp;
        emit ValueUpdated(vault, _value, block.timestamp);
    }

    function getValue(address vault) external view returns (uint256) {
        return values;
    }

    function getLastUpdateTimestamp(address vault) external view returns (uint256) {
        return timestamps;
    }
}