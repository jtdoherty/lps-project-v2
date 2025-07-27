// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurve2Pool {
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function coins(int128 i) external view returns (address);
    // ADD THIS FUNCTION
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
}