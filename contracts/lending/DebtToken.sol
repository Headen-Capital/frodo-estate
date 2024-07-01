// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DebtToken is ERC20, Ownable {
    address public lendingPool;

    constructor(string memory name, string memory symbol, address _lendingPool, address owner) ERC20(name, symbol) {
        lendingPool = _lendingPool;
        transferOwnership(owner);
    }

    function setLendingPool(address _lendingPool) external onlyOwner {
        lendingPool = _lendingPool;
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == lendingPool, "Only lending pool can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == lendingPool, "Only lending pool can burn");
        _burn(_from, _amount);
    }

    // Override transfer functions to make the token non-transferrable
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Debt tokens are non-transferrable");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Debt tokens are non-transferrable");
    }
}