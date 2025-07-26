// In src/mocks/MockYVault.sol
// FULL AND FINAL CORRECTED FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IYearnVault.sol";
import "../interfaces/IERC20withDecimals.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockYVault is IYearnVault, ERC20, Ownable {
    using SafeERC20 for IERC20withDecimals;

    IERC20withDecimals public immutable underlying;
    uint256 public pricePerShare;

    constructor(address _underlying) ERC20("Mock Yearn Vault Token", "myvTKN") Ownable(msg.sender) {
        underlying = IERC20withDecimals(_underlying);
        pricePerShare = 1e18; // Start with a 1:1 price
    }
    
    // --- THE FIX IS HERE ---
    // This resolves the compiler error. Because both ERC20 and IYearnVault have a
    // 'balanceOf' function, we must explicitly override it. We are choosing to use
    // the standard behavior from the ERC20 contract.
    function balanceOf(address account) public view override(IYearnVault, ERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    // Function for owner to add "yield" to the vault
    function drip(uint256 amount) external {
        underlying.safeTransferFrom(msg.sender, address(this), amount);
    }
    
    function deposit(uint256 _amount) external override returns (uint256) {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 shares = (_amount * 1e18) / pricePerShare;
        _mint(msg.sender, shares);
        return shares;
    }

    function withdraw(uint256 _shares) external override returns (uint256) {
        uint256 totalAssets = (_shares * pricePerShare) / 1e18;
        _burn(msg.sender, _shares);
        underlying.safeTransfer(msg.sender, totalAssets);
        return totalAssets;
    }

    function setPricePerShare(uint256 newPrice) external onlyOwner {
        pricePerShare = newPrice;
    }

    // This is just a placeholder to satisfy the interface
    function harvest() external override {}
}