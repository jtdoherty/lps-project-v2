// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";
import "../src/mocks/MockYVault.sol";
import "../src/mocks/MockERC20.sol";

contract HarvestTest is Test {
    DepositController public controller;
    StakingPool public stakingPool;
    LpUSD public lpUSD;
    SlpUSD public slpUSD;
    MockERC20 public underlyingToken;
    MockYVault public mockVault;

    address user = address(1);
    address deployer = address(this);

    function setUp() public {
        underlyingToken = new MockERC20("Mock DAI", "mDAI");
        mockVault = new MockYVault(address(underlyingToken));
        lpUSD = new LpUSD(deployer);
        slpUSD = new SlpUSD(deployer);

        controller = new DepositController(
            address(mockVault), 
            address(lpUSD), 
            address(underlyingToken), 
            deployer
        );
        stakingPool = new StakingPool(address(lpUSD), address(slpUSD), deployer);

        controller.setStakingPool(address(stakingPool));
        lpUSD.grantRole(lpUSD.MINTER_ROLE(), address(controller));
        slpUSD.grantRole(slpUSD.MINTER_ROLE(), address(stakingPool));
    }

    function test_Harvest_DeliversYieldToStakingPool() public {
        uint256 initialDeposit = 10_000 * 1e18;
        underlyingToken.mint(user, initialDeposit);
        vm.startPrank(user);
        underlyingToken.approve(address(controller), initialDeposit);
        controller.deposit(initialDeposit);
        vm.stopPrank();

        uint256 lpUsdBalance = lpUSD.balanceOf(user);
        vm.startPrank(user);
        lpUSD.approve(address(stakingPool), lpUsdBalance);
        stakingPool.stake(lpUsdBalance);
        vm.stopPrank();

        assertEq(stakingPool.totalLpUSD(), 10_000 * 1e6);

        mockVault.setPricePerShare(1.1e18); // Simulate 10% yield

        vm.prank(deployer);
        controller.harvest();
        
        uint256 finalPoolBalance = stakingPool.totalLpUSD();
        assertApproxEqAbs(finalPoolBalance, 11_000 * 1e6, 1);
    }
}