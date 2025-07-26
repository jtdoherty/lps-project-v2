// In src/StakingPool.sol
// FULL AND FINAL ARCHITECTURALLY-SOUND FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./tokens/LpUSD.sol";
import "./tokens/SlpUSD.sol";

contract StakingPool is Ownable {
    using SafeERC20 for LpUSD;
    using SafeERC20 for SlpUSD;

    LpUSD public immutable lpUSD;
    SlpUSD public immutable slpUSD;

    event Staked(address indexed user, uint256 lpUsdAmount, uint256 slpUsdAmount);
    event Unstaked(address indexed user, uint256 slpUsdAmount, uint256 lpUsdAmount);

    // Constructor is now simpler again.
    constructor(
        address _lpUsdAddress, 
        address _slpUsdAddress, 
        address _initialOwner
    ) Ownable(_initialOwner) {
        lpUSD = LpUSD(_lpUsdAddress);
        slpUSD = SlpUSD(_slpUsdAddress);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        
        // --- THE FINAL FIX IS HERE ---
        // The pool's value is now its own balance, because the harvest() function
        // tops it up with yield. This makes the logic much simpler and safer.
        uint256 pool = lpUSD.balanceOf(address(this));
        uint256 supply = slpUSD.totalSupply();
        uint256 shares;

        if (supply == 0 || pool == 0) {
            shares = _amount;
        } else {
            shares = (_amount * supply) / pool;
        }
        require(shares > 0, "Insufficient shares");
        
        lpUSD.safeTransferFrom(msg.sender, address(this), _amount);
        slpUSD.mint(msg.sender, shares);

        emit Staked(msg.sender, _amount, shares);
    }

    function unstake(uint256 _shares) external {
        require(_shares > 0, "Cannot unstake 0");
        
        uint256 pool = lpUSD.balanceOf(address(this));
        uint256 supply = slpUSD.totalSupply();
        uint256 amount = (_shares * pool) / supply;
        require(amount > 0, "Insufficient amount");
        
        slpUSD.burnFrom(msg.sender, _shares);
        lpUSD.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, _shares, amount);
    }
}