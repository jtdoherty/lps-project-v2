// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IYearnVault} from "../interfaces/IYearnVault.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract MockYVault is IYearnVault, ERC20, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable underlying;
    uint256 public pricePerShare = 10**18;

    constructor(
        address _underlying,
        address _initialOwner
    ) ERC20("Mock Yearn Vault", "myvTKN") Ownable(_initialOwner) {
        underlying = IERC20(_underlying);
    }

    // --- Admin Functions ---

    function setPricePerShare(uint256 _price) external onlyOwner {
        pricePerShare = _price;
    }

    function drip(uint256 _amount) external {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // --- IYearnVault Interface Implementation ---

    function deposit(
        uint256 _amount,
        address _receiver
    ) public override returns (uint256 shares) {
        uint256 totalAssets = underlying.balanceOf(address(this));
        uint256 currentSupply = totalSupply();
        if (currentSupply == 0 || totalAssets == 0) {
            shares = _amount;
        } else {
            shares = (_amount * currentSupply) / totalAssets;
        }
        _mint(_receiver, shares);
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(
        uint256 _shares,
        address _receiver,
        address, // _owner is unused in mock
        uint256 // _slippage is unused in mock
    ) public override returns (uint256 assets) {
        uint256 totalAssets = underlying.balanceOf(address(this));
        uint256 currentSupply = totalSupply();
        assets = (_shares * totalAssets) / currentSupply;
        _burn(msg.sender, _shares);
        underlying.safeTransfer(_receiver, assets);
    }

    function previewRedeem(
        uint256 _shares
    ) public view override returns (uint256) {
        return (_shares * pricePerShare) / 10**18;
    }

    function token() external view override returns (address) {
        return address(underlying);
    }
    
    // Explicitly override to resolve inheritance conflict
    function balanceOf(address _account) public view override(IYearnVault, ERC20) returns (uint256) {
        return super.balanceOf(_account);
    }

    // Dummy implementation to satisfy the interface
    function harvest() external override {
        // In a real vault, this triggers strategies. In our mock, it does nothing.
    }
}