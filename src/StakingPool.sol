// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { LpUSD } from "./tokens/LpUSD.sol";
import { SlpUSD } from "./tokens/SlpUSD.sol";

contract StakingPool is Ownable, ReentrancyGuard {

    LpUSD public lpUsd;
    SlpUSD public slpUsd;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);

    constructor(
        address _lpUsdAddress,
        address _slpUsdAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        lpUsd = LpUSD(_lpUsdAddress);
        slpUsd = SlpUSD(_slpUsdAddress);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0");

        uint256 totalLpUsdInPool = lpUsd.balanceOf(address(this));
        uint256 totalSlpUsdSupply = slpUsd.totalSupply();

        uint256 slpUsdToMint;
        if (totalSlpUsdSupply == 0) {
            slpUsdToMint = _amount;
        } else {
            slpUsdToMint = (_amount * totalSlpUsdSupply) / totalLpUsdInPool;
        }

        lpUsd.transferFrom(msg.sender, address(this), _amount);
        slpUsd.mint(msg.sender, slpUsdToMint);

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _slpUsdAmount) external nonReentrant {
        require(_slpUsdAmount > 0, "Cannot unstake 0");

        uint256 totalLpUsdInPool = lpUsd.balanceOf(address(this));
        uint256 totalSlpUsdSupply = slpUsd.totalSupply();
        
        uint256 lpUsdToReturn = (_slpUsdAmount * totalLpUsdInPool) / totalSlpUsdSupply;

        slpUsd.burnFrom(msg.sender, _slpUsdAmount);
        lpUsd.transfer(msg.sender, lpUsdToReturn);

        emit Unstake(msg.sender, _slpUsdAmount);
    }
}