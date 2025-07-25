// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC20withDecimals.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// This is an upgraded mock of a Yearn Vault for testing yield generation.
contract MockYVault is ERC20 {
    using SafeERC20 for IERC20withDecimals;

    IERC20withDecimals public immutable asset;
    uint256 private _pricePerShare;

    constructor(address _asset) ERC20("Mock yvToken", "myvTKN") {
        asset = IERC20withDecimals(_asset);
        // Start with a price of 1.0 (with 18 decimals of precision)
        _pricePerShare = 1e18;
    }

    /// @notice The price of one share in terms of the underlying asset.
    function pricePerShare() external view returns (uint256) {
        return _pricePerShare;
    }
    
    /// @notice Manually set the price per share to simulate yield. (For testing only!)
    function setPricePerShare(uint256 newPrice) external {
        _pricePerShare = newPrice;
    }

    function deposit(uint256 amount, address receiver) public returns (uint256) {
        asset.safeTransferFrom(msg.sender, address(this), amount);
        // Calculate shares to mint based on the current price
        uint256 shares = (amount * 1e18) / _pricePerShare;
        _mint(receiver, shares);
        return shares;
    }

    function deposit() external returns (uint256) {
        uint256 amount = asset.allowance(msg.sender, address(this));
        return deposit(amount, msg.sender);
    }
    
    function withdraw(uint256 assets, address receiver) external returns (uint256) {
        // Calculate shares to burn based on the current price
        uint256 shares = (assets * 1e18) / _pricePerShare;
        _burn(msg.sender, shares);
        asset.safeTransfer(receiver, assets);
        return assets;
    }

    function totalAssets() external view returns (uint256) {
        // Total assets = total shares * price / 1e18
        return (totalSupply() * _pricePerShare) / 1e18;
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return (shares * _pricePerShare) / 1e18;
    }
}