// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IYearnVault {
    function deposit() external returns (uint256);
    function deposit(uint256 amount, address receiver) external returns (uint256);
    function withdraw(uint256 maxShares, address receiver, uint256 maxLoss) external returns (uint256);
    function pricePerShare() external view returns (uint256);
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
}
