// In src/DepositController.sol
// FULL, FINAL, AND ARCHITECTURALLY-SOUND FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IYearnVault.sol";
import "./interfaces/IERC20withDecimals.sol";
import "./tokens/LpUSD.sol";

contract DepositController is Ownable {
    using SafeERC20 for IERC20withDecimals;
    using SafeERC20 for LpUSD;

    IYearnVault public immutable yvTokenVault;
    LpUSD public immutable lpUSD;
    IERC20withDecimals public immutable underlying;
    address public stakingPool;

    event StakingPoolSet(address newStakingPool);
    event Harvested(uint256 yield);

    constructor(
        address _yvTokenAddress,
        address _lpUsdAddress,
        address _underlyingAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        yvTokenVault = IYearnVault(_yvTokenAddress);
        lpUSD = LpUSD(_lpUsdAddress);
        underlying = IERC20withDecimals(_underlyingAddress);
    }

    function setStakingPool(address _stakingPoolAddress) external onlyOwner {
        stakingPool = _stakingPoolAddress;
        emit StakingPoolSet(_stakingPoolAddress);
    }

    function deposit(uint256 _amount) external {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        underlying.approve(address(yvTokenVault), _amount);
        yvTokenVault.deposit(_amount);
        lpUSD.mint(msg.sender, _amount);
    }

    function redeem(uint256 _lpUsdAmount) external {
        lpUSD.burnFrom(msg.sender, _lpUsdAmount);
        uint256 pricePerShare = yvTokenVault.pricePerShare();
        uint256 sharesToWithdraw = (_lpUsdAmount * 1e18) / pricePerShare;
        uint256 underlyingReceived = yvTokenVault.withdraw(sharesToWithdraw);
        underlying.safeTransfer(msg.sender, underlyingReceived);
    }

    // --- THE FINAL, CORRECT HARVEST LOGIC ---
    function harvest() external {
        // Step 1: Find out how many Yearn Vault shares this contract owns.
        uint256 sharesHeld = yvTokenVault.balanceOf(address(this));
        
        // Step 2: Get the current value of one share.
        uint256 price = yvTokenVault.pricePerShare();
        
        // Step 3: Calculate the total real value of our assets in the vault.
        uint256 totalValue = (sharesHeld * price) / 1e18;
        
        // Step 4: Get the total amount of lpUSD we've already issued.
        uint256 totalLpSupply = lpUSD.totalSupply();
        
        // Step 5: If our assets are worth more than our liabilities, the difference is profit.
        if (totalValue > totalLpSupply) {
            uint256 yield = totalValue - totalLpSupply;
            
            // Step 6: Mint new lpUSD for the profit and send it to the StakingPool.
            // THIS is the bridge that delivers the value to stakers.
            lpUSD.mint(stakingPool, yield);
            emit Harvested(yield);
        }
    }
}