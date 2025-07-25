// in src/interfaces/IERC20withDecimals.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// This interface extends the standard IERC20 to include the optional `decimals` function.
interface IERC20withDecimals is IERC20 {
    function decimals() external view returns (uint8);
}