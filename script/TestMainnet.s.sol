// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { DeployAll } from "./DeployAll.s.sol";
import { DepositController } from "../src/DepositController.sol";
import { IERC20withDecimals } from "../src/interfaces/IERC20withDecimals.sol";
import { StakingPool } from "../src/StakingPool.sol";
import { LpUSD } from "../src/tokens/LpUSD.sol";
import { SlpUSD } from "../src/tokens/SlpUSD.sol";

contract TestMainnet is Script {

    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC; 
    address constant CRV2POOL_WHALE = 0x479dFB03cdDEa20dC4e8788B81Fd7C7A08FD3555;

    IERC20withDecimals usdc = IERC20withDecimals(USDC_ADDRESS);
    LpUSD lpUsd;
    SlpUSD slpUsd;
    DepositController depositController;
    StakingPool stakingPool;

    function run() external {
        string memory mainnetRpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(mainnetRpcUrl);

        DeployAll deployer = new DeployAll();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);

        (address lpUsdAddr, address slpUsdAddr, address dcAddr, address spAddr) = deployer.run();

        lpUsd = LpUSD(lpUsdAddr);
        slpUsd = SlpUSD(slpUsdAddr);
        depositController = DepositController(dcAddr);
        stakingPool = StakingPool(spAddr);

        uint256 initialAmount = 100_000 * (10 ** 6);
        vm.startPrank(USDC_WHALE);
        usdc.transfer(user, initialAmount);
        vm.stopPrank();
        console.log("User's starting USDC balance: 100,000.00");

        vm.startBroadcast(deployerPrivateKey);
        
        console.log("--- Journey A: User Deposits 100,000 USDC ---");
        usdc.approve(address(depositController), initialAmount);
        depositController.deposit(initialAmount);
        uint256 lpUsdBalance = lpUsd.balanceOf(user);
        console.log("User's lpUSD balance after deposit:", lpUsdBalance / 1e18);

        console.log("--- Journey B: User Stakes lpUSD ---");
        lpUsd.approve(address(stakingPool), lpUsdBalance);
        stakingPool.stake(lpUsdBalance);
        uint256 slpUsdBalance = slpUsd.balanceOf(user);
        console.log("User's slpUSD balance after staking:", slpUsdBalance / 1e18);

        vm.stopBroadcast();

        console.log("--- Journey C & D: Simulate Profit and Harvest ---");
        address crv2poolAddress = address(depositController.depositToken());
        uint256 simulatedProfit = 1_000 * (10 ** 18);
        vm.startPrank(CRV2POOL_WHALE);
        IERC20withDecimals(crv2poolAddress).transfer(address(depositController), simulatedProfit);
        vm.stopPrank();
        
        vm.startBroadcast(deployerPrivateKey);
        depositController.harvest();
        vm.stopBroadcast();
        console.log("Harvest successful.");

        vm.startBroadcast(deployerPrivateKey);

        console.log("--- Journey E: User Unstakes for Profit ---");
        stakingPool.unstake(slpUsdBalance);
        uint256 finalLpUsdBalance = lpUsd.balanceOf(user);
        console.log("User's final lpUSD balance:", finalLpUsdBalance / 1e18);

        console.log("--- Journey F: User Redeems for More USDC ---");
        lpUsd.approve(address(depositController), finalLpUsdBalance);
        depositController.redeem(finalLpUsdBalance);
        uint256 finalUsdcBalance = usdc.balanceOf(user);
        console.log("User's final USDC balance:", finalUsdcBalance / 1e6);
        
        vm.stopBroadcast();

        console.log(unicode"✅ ✅ ✅ --- FULL JOURNEY SUCCESSFUL ON MAINNET FORK --- ✅ ✅ ✅");
    }
}