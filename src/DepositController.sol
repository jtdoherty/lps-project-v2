// In src/DepositController.sol
// FULL AND CORRECTED FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IYearnVault.sol";
import "./interfaces/IERC20withDecimals.sol";
import "./tokens/LpUSD.sol";
import "./StakingPool.sol";

contract DepositController is Ownable {
    using SafeERC20 for IERC20withDecimals;
    using SafeERC20 for LpUSD;

    IYearnVault public immutable yvTokenVault;
    LpUSD public immutable lpUSD;
    IERC20withDecimals public immutable underlying;
    StakingPool public stakingPool;

    event StakingPoolSet(address newStakingPool);

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
        stakingPool = StakingPool(_stakingPoolAddress);
        emit StakingPoolSet(_stakingPoolAddress);
    }

    function deposit(uint256 _amount) external {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        // FIX: Using standard 'approve' which is correct here
        underlying.approve(address(yvTokenVault), _amount);
        yvTokenVault.deposit(_amount);
        lpUSD.mint(msg.sender, _amount);
    }

    function redeem(uint256 _lpUsdAmount) external {
        // This now requires the MINTER_ROLE on LpUSD to call burnFrom
        lpUSD.burnFrom(msg.sender, _lpUsdAmount);

        uint256 pricePerShare = yvTokenVault.pricePerShare();
        uint256 sharesToWithdraw = (_lpUsdAmount * 1e18) / pricePerShare;
        
        uint256 underlyingReceived = yvTokenVault.withdraw(sharesToWithdraw);

        underlying.safeTransfer(msg.sender, underlyingReceived);
    }

    function harvest() external {
        // FIX: Renamed 'before' and 'after' to avoid reserved keyword
        uint256 sharesBefore = yvTokenVault.balanceOf(address(this));
        yvTokenVault.harvest();
        uint256 sharesAfter = yvTokenVault.balanceOf(address(this));
        
        if (sharesAfter > sharesBefore) {
            uint256 gainedShares = sharesAfter - sharesBefore;
            uint256 price = yvTokenVault.pricePerShare();
            uint256 valueGained = (gainedShares * price) / 1e18;
            
            // This now requires the MINTER_ROLE on LpUSD to mint to the staking pool
            lpUSD.mint(address(stakingPool), valueGained);
            stakingPool.harvest(valueGained);
        }
    }
}