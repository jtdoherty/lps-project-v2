// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/AccessControl.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract SlpUSD is ERC20, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        address initialOwner
    ) ERC20("Staked Liquid Pool USD", "slpUSD") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burn(account, amount);
    }
}