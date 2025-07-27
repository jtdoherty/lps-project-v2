// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IYearnVault {
    function deposit(uint256 amount, address receiver) external returns (uint256);
    function withdraw(uint256 maxShares, address receiver, address owner, uint256 slippage) external returns (uint256);
    function previewRedeem(uint256 shares) external view returns (uint256);
    function token() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function harvest() external;
}