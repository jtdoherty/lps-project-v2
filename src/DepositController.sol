// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IYearnVault.sol";
import "./interfaces/IERC20withDecimals.sol";
import "./tokens/LpUSD.sol";

contract DepositController is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IYearnVault public immutable yVault;
    IERC20 public immutable underlyingAsset;
    LpUSD public immutable lpUSD;
    address public stakingPool;

    event Deposited(address indexed user, uint256 assetAmount, uint256 lpUsdMinted);
    event Redeemed(address indexed user, uint256 lpUsdBurned, uint256 assetAmount);
    event Harvested(uint256 yieldAmount, uint256 lpUsdCreated);
    event StakingPoolSet(address indexed newStakingPool);

    constructor(
        address _yVaultAddress,
        address _lpUsdAddress,
        address _underlyingAssetAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        yVault = IYearnVault(_yVaultAddress);
        underlyingAsset = IERC20(_underlyingAssetAddress);
        lpUSD = LpUSD(_lpUsdAddress);
    }

    function setStakingPool(address _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
        emit StakingPoolSet(_stakingPool);
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Deposit amount must be positive");
        underlyingAsset.safeTransferFrom(msg.sender, address(this), _amount);
        _mintLpUSD(_amount, msg.sender);
    }

    function redeem(uint256 _lpUsdAmount) external nonReentrant {
        require(_lpUsdAmount > 0, "Redeem amount must be positive");
        lpUSD.burnFrom(msg.sender, _lpUsdAmount);
        uint256 underlyingDecimals = IERC20withDecimals(address(underlyingAsset)).decimals();
        uint256 underlyingToWithdraw = (_lpUsdAmount * (10**underlyingDecimals)) / (10**lpUSD.decimals());
        uint256 assetsReceived = yVault.withdraw(underlyingToWithdraw, msg.sender);
        emit Redeemed(msg.sender, _lpUsdAmount, assetsReceived);
    }

    function harvest() external returns (uint256) {
        require(stakingPool != address(0), "Staking pool not set");
        uint256 totalShares = IERC20(address(yVault)).balanceOf(address(this));
        uint256 totalValue = yVault.previewRedeem(totalShares);
        uint256 underlyingDecimals = IERC20withDecimals(address(underlyingAsset)).decimals();
        uint256 liabilities = (lpUSD.totalSupply() * (10**underlyingDecimals)) / (10**lpUSD.decimals());

        if (totalValue <= liabilities) return 0;
        uint256 yield = totalValue - liabilities;

        yVault.withdraw(yield, address(this));
        _mintLpUSD(yield, stakingPool);
        
        uint256 lpUsdMinted = (yield * (10**lpUSD.decimals())) / (10**underlyingDecimals);
        emit Harvested(yield, lpUsdMinted);
        return yield;
    }

    function _mintLpUSD(uint256 _underlyingAmount, address _recipient) internal {
        underlyingAsset.approve(address(yVault), _underlyingAmount);
        uint256 sharesReceived = yVault.deposit();
        require(sharesReceived > 0, "Yearn deposit failed");

        uint256 underlyingDecimals = IERC20withDecimals(address(underlyingAsset)).decimals();
        uint256 amountToMint = (_underlyingAmount * (10**lpUSD.decimals())) / (10**underlyingDecimals);
        
        lpUSD.mint(_recipient, amountToMint);
        emit Deposited(_recipient, _underlyingAmount, amountToMint);
    }
}