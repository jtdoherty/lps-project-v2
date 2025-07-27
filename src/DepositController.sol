// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IYearnVault } from "./interfaces/IYearnVault.sol";
import { ICurve2Pool } from "./interfaces/ICurve2Pool.sol";
import { LpUSD } from "./tokens/LpUSD.sol";
import { StakingPool } from "./StakingPool.sol";

contract DepositController is Ownable, ReentrancyGuard {
    IYearnVault public yVault;
    IERC20 public depositToken;
    IERC20 public underlyingToken;
    ICurve2Pool public curvePool;
    LpUSD public lpUsd;
    StakingPool public stakingPool;
    uint256 public slippageBps = 10; // 0.1% slippage tolerance (10 basis points)

    event Deposit(address indexed user, uint256 underlyingAmount, uint256 lpUsdAmount);
    // ... (rest of events and constructor are unchanged)
    event Redeem(address indexed user, uint256 lpUsdAmount, uint256 underlyingAmount);
    event Harvest(address indexed caller, uint256 profitAmount);
    event StakingPoolSet(address indexed newStakingPool);

    constructor(
        address _yVault,
        address _lpUsd,
        address _underlyingToken,
        address _curvePool,
        uint8 _underlyingIndex,
        address _initialOwner
    ) Ownable(_initialOwner) {
        yVault = IYearnVault(_yVault);
        lpUsd = LpUSD(_lpUsd);
        underlyingToken = IERC20(_underlyingToken);
        curvePool = ICurve2Pool(_curvePool);
        depositToken = IERC20(yVault.token());
    }

    function deposit(uint256 _underlyingAmount) external nonReentrant {
        require(_underlyingAmount > 0, "Deposit amount must be positive");
        _safeTransferFrom(underlyingToken, msg.sender, address(this), _underlyingAmount);
        
        uint256 scaledAmount = _underlyingAmount * (10 ** 12);
        _safeApprove(underlyingToken, address(curvePool), 0);
        _safeApprove(underlyingToken, address(curvePool), scaledAmount);
        
        uint256[2] memory amounts;
        amounts[0] = scaledAmount;
        
        // --- FINAL UPGRADE: REALISTIC SLIPPAGE ---
        // Since the price of the LP token is very close to $1, we can use the
        // scaled amount as a proxy for the expected amount of LP tokens.
        uint256 minCrvTokens = scaledAmount * (10000 - slippageBps) / 10000;
        
        uint256 crvTokensReceived = curvePool.add_liquidity(amounts, minCrvTokens);
        
        require(crvTokensReceived > 0, "Received 0 crv tokens from Curve");
        _safeApprove(depositToken, address(yVault), 0);
        _safeApprove(depositToken, address(yVault), crvTokensReceived);
        yVault.deposit(crvTokensReceived, address(this));
        
        uint256 lpUsdToMint = scaledAmount;
        lpUsd.mint(msg.sender, lpUsdToMint);
        emit Deposit(msg.sender, _underlyingAmount, lpUsdToMint);
    }
    
    // ... (rest of the contract is unchanged)
    function redeem(uint256 _lpUsdAmount) external nonReentrant {
        require(_lpUsdAmount > 0, "Redeem amount must be positive");
        uint256 totalLpSupply = lpUsd.totalSupply();
        require(totalLpSupply > 0, "Cannot redeem from empty pool");

        uint256 vaultSharesOwned = yVault.balanceOf(address(this));
        uint256 sharesToWithdraw = (_lpUsdAmount * vaultSharesOwned) / totalLpSupply;

        lpUsd.burnFrom(msg.sender, _lpUsdAmount);
        uint256 crvTokensReceived = yVault.withdraw(sharesToWithdraw, address(this), address(this), 0);
        _safeApprove(depositToken, address(curvePool), 0);
        _safeApprove(depositToken, address(curvePool), crvTokensReceived);
        
        uint256 expectedUnderlying = crvTokensReceived / (10 ** 12);
        uint256 minUnderlying = expectedUnderlying * (10000 - slippageBps) / 10000;

        uint256 underlyingReceived = curvePool.remove_liquidity_one_coin(crvTokensReceived, 0, minUnderlying);
        
        _safeTransfer(underlyingToken, msg.sender, underlyingReceived);
        emit Redeem(msg.sender, _lpUsdAmount, underlyingReceived);
    }

    function totalValue() public view returns (uint256) {
        uint256 ourShares = yVault.balanceOf(address(this));
        if (ourShares == 0) return 0;
        
        uint256 ourCrvTokens = yVault.previewRedeem(ourShares);
        uint256 usdcValue = curvePool.calc_withdraw_one_coin(ourCrvTokens, 0);
        return usdcValue * (10 ** 12);
    }

    function harvest() external nonReentrant {
        require(address(stakingPool) != address(0), "Staking pool not set");
        uint256 currentValue = totalValue();
        uint256 principal = lpUsd.totalSupply();
        if (currentValue > principal) {
            uint256 profit = currentValue - principal;
            lpUsd.mint(address(stakingPool), profit);
            emit Harvest(msg.sender, profit);
        }
    }

    function setStakingPool(address _stakingPool) external onlyOwner {
        require(address(stakingPool) == address(0), "Staking pool already set");
        stakingPool = StakingPool(_stakingPool);
        emit StakingPoolSet(_stakingPool);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(underlyingToken) && _tokenAddress != address(depositToken), "Cannot recover core token");
        _safeTransfer(IERC20(_tokenAddress), owner(), _tokenAmount);
    }

    function _safeApprove(IERC20 token, address spender, uint256 value) private {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAFE_APPROVE_FAILED");
    }

    function _safeTransfer(IERC20 token, address to, uint256 value) private {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAFE_TRANSFER_FAILED");
    }

    function _safeTransferFrom(IERC20 token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAFE_TRANSFER_FROM_FAILED");
    }
}