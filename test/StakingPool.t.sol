// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/IYearnVault.sol";

contract StakingPoolTest is Test {
    DepositController public controller;
    StakingPool public stakingPool;
    LpUSD public lpUSD;
    SlpUSD public slpUSD;
    IERC20 public daiToken;

    address yvDaiVault;
    address daiAddress;
    address userA;
    address deployer;

    function setUp() public {
        yvDaiVault = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
        daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        userA = address(0xA);
        deployer = address(this);

        uint256 forkBlock = 20000000;
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), forkBlock);

        daiToken = IERC20(daiAddress);
        lpUSD = new LpUSD(deployer);
        slpUSD = new SlpUSD(deployer);

        // Add `deployer` as the 4th argument
        controller = new DepositController(yvDaiVault, address(lpUSD), daiAddress, deployer);
        stakingPool = new StakingPool(address(lpUSD), address(slpUSD), deployer);
        
        lpUSD.grantRole(lpUSD.MINTER_ROLE(), address(controller));
        slpUSD.grantRole(slpUSD.MINTER_ROLE(), address(stakingPool));
    }

    function test_Stake_Harvest_Unstake_FullFlow() public {
        uint256 initialDai = 1_000 * 1e18;
        deal(daiAddress, userA, initialDai);

        vm.startPrank(userA);
        daiToken.approve(address(controller), initialDai);
        controller.deposit(initialDai);
        vm.stopPrank();
        
        uint256 lpUsdBalance = lpUSD.balanceOf(userA);
        assertEq(lpUsdBalance, 1_000 * 1e6);

        vm.startPrank(userA);
        lpUSD.approve(address(stakingPool), lpUsdBalance);
        stakingPool.stake(lpUsdBalance);
        vm.stopPrank();

        assertEq(lpUSD.balanceOf(userA), 0);
        uint256 slpUsdBalance = slpUSD.balanceOf(userA);
        assertTrue(slpUsdBalance > 0);
        
        uint256 yieldAmount = 100 * 1e6;
        deal(address(lpUSD), deployer, yieldAmount);
        
        vm.startPrank(deployer);
        lpUSD.approve(address(stakingPool), yieldAmount);
        stakingPool.harvest(yieldAmount);
        vm.stopPrank();

        assertEq(stakingPool.totalLpUSD(), (1_000 + 100) * 1e6);

        vm.startPrank(userA);
        slpUSD.approve(address(stakingPool), slpUsdBalance);
        stakingPool.unstake(slpUsdBalance);
        vm.stopPrank();

        uint256 finalLpUsdBalance = lpUSD.balanceOf(userA);
        assertEq(finalLpUsdBalance, (1_000 + 100) * 1e6);
    }
}