// In src/tokens/LpUSD.sol
// FULL AND CORRECTED FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LpUSD is ERC20, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _initialAdmin) ERC20("LpUSD Token", "lpUSD") Ownable(_initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);
        _grantRole(MINTER_ROLE, _initialAdmin);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a burner");
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }
}