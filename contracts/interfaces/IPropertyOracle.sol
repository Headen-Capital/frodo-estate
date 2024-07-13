// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IPropertyOracle is IAccessControl {
    // Events
    event ValueUpdated(address indexed vault, uint256 newValue, uint256 timestamp);

    // Constants
    function UPDATER_ROLE() external view returns (bytes32);

    // Functions
    function updateValue(address vault, uint256 _value) external;
    function getValue(address vault) external view returns (uint256);
    function getLastUpdateTimestamp(address vault) external view returns (uint256);

    // Inherited from IAccessControl, but not explicitly declared here
}