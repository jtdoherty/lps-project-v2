// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract LpUSD is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin) ERC20("Liquid LP USD", "lpUSD") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    // --- THIS IS THE FIX ---
    // We override the default decimals function to match USDC's 6 decimals.
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /// @notice Creates new lpUSD tokens.
    /// @dev Can only be called by an address with MINTER_ROLE.
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}