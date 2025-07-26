// In src/interfaces/IYearnVault.sol
// FULLY REPLACED AND SIMPLIFIED FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IYearnVault {
    function deposit(uint256 amount) external returns (uint256);
    function withdraw(uint256 maxShares) external returns (uint256);
    function pricePerShare() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function harvest() external;
}