// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IYearnVault.sol";
import "./tokens/LpUSD.sol";

contract DepositController is ReentrancyGuard {
    IYearnVault public immutable yVault;
    IERC20 public immutable underlyingAsset;
    LpUSD public immutable lpUSD;

    event Deposited(address indexed user, uint256 assetAmount, uint256 lpUsdMinted);
    event Redeemed(address indexed user, uint256 lpUsdBurned, uint256 assetAmount);

    constructor(
        address _yVaultAddress,
        address _lpUsdAddress,
        address _underlyingAssetAddress
    ) {
        yVault = IYearnVault(_yVaultAddress);
        underlyingAsset = IERC20(_underlyingAssetAddress);
        lpUSD = LpUSD(_lpUsdAddress);
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Deposit amount must be positive");

        underlyingAsset.transferFrom(msg.sender, address(this), _amount);
        underlyingAsset.approve(address(yVault), _amount);
        uint256 sharesReceived = yVault.deposit();
        require(sharesReceived > 0, "Yearn deposit failed");

        // Scale the 18-decimal DAI amount down to our 6-decimal lpUSD amount.
        uint256 amountToMint = _amount / 1e12;

        // ==========================================================
        //  THE FINAL BUG FIX IS HERE: We use `amountToMint` now.
        // ==========================================================
        lpUSD.mint(msg.sender, amountToMint);

        // Also update the event to be accurate.
        emit Deposited(msg.sender, _amount, amountToMint);
    }

    function redeem(uint256 _lpUsdAmount) external nonReentrant {
        require(_lpUsdAmount > 0, "Redeem amount must be positive");
        lpUSD.transferFrom(msg.sender, address(this), _lpUsdAmount);
        uint256 totalShares = IERC20(address(yVault)).balanceOf(address(this));
        uint256 totalControllerAssets = yVault.previewRedeem(totalShares);
        uint256 sharesToWithdraw = (_lpUsdAmount * totalShares) / totalControllerAssets;
        uint256 assetsReceived = yVault.withdraw(sharesToWithdraw, msg.sender, 100);
        emit Redeemed(msg.sender, _lpUsdAmount, assetsReceived);
    }
}