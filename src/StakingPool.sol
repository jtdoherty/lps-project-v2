// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./tokens/LpUSD.sol";
import "./tokens/SlpUSD.sol";

contract StakingPool is Ownable {
    using SafeERC20 for LpUSD;

    LpUSD public immutable lpUSD;
    SlpUSD public immutable slpUSD;

    event Staked(address indexed user, uint256 lpUsdAmount, uint256 slpUsdAmount);
    event Unstaked(address indexed user, uint256 slpUsdAmount, uint256 lpUsdAmount);
    event Harvested(address indexed harvester, uint256 lpUsdAmount);

    constructor(address _lpUsdAddress, address _slpUsdAddress, address _initialOwner) Ownable(_initialOwner) {
        lpUSD = LpUSD(_lpUsdAddress);
        slpUSD = SlpUSD(_slpUsdAddress);
    }

    /// @notice The total amount of lpUSD tokens held by this staking contract.
    function totalLpUSD() public view returns (uint256) {
        return lpUSD.balanceOf(address(this));
    }

    /// @notice Stakes lpUSD to receive slpUSD shares.
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");

        uint256 pool = totalLpUSD();
        uint256 supply = slpUSD.totalSupply();
        uint256 shares;

        if (supply == 0) {
            // If we are the first to stake, 1 lpUSD = 1 slpUSD
            shares = _amount;
        } else {
            // The number of shares we get is proportional to our share of the pool
            shares = (_amount * supply) / pool;
        }

        require(shares > 0, "Insufficient shares");
        
        lpUSD.safeTransferFrom(msg.sender, address(this), _amount);
        slpUSD.mint(msg.sender, shares);

        emit Staked(msg.sender, _amount, shares);
    }

    /// @notice Burns slpUSD shares to redeem a proportional amount of lpUSD.
    function unstake(uint256 _shares) external {
        require(_shares > 0, "Cannot unstake 0");
        
        uint256 pool = totalLpUSD();
        uint256 supply = slpUSD.totalSupply();
        
        // The amount of lpUSD we get is proportional to our share of the pool
        uint256 amount = (_shares * pool) / supply;

        require(amount > 0, "Insufficient amount");

        // Note: For burning, the user must first approve this contract to spend their slpUSD.
        // A more advanced contract would have a `burnFrom` function on the token.
        slpUSD.burnFrom(msg.sender, _shares);

        lpUSD.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, _shares, amount);
    }
    
    /// @notice Adds yield (in lpUSD) to the pool. Can only be called by the owner.
    /// @dev In a real system, this would be permissionless and incentivized.
    function harvest(uint256 _amount) external onlyOwner {
        // This function pulls pre-approved lpUSD from the owner's wallet and
        // adds it to the pool as pure yield.
        lpUSD.safeTransferFrom(msg.sender, address(this), _amount);
        emit Harvested(msg.sender, _amount);
    }
}