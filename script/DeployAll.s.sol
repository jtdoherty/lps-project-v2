// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { LpUSD } from "../src/tokens/LpUSD.sol";
import { SlpUSD } from "../src/tokens/SlpUSD.sol";
import { DepositController } from "../src/DepositController.sol";
import { StakingPool } from "../src/StakingPool.sol";

contract DeployAll is Script {
    address constant YVAULT_ADDRESS = 0xfBd4d8bf19c67582168059332c46567563d0d75f;
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant CURVE_POOL_ADDRESS = 0x4f493B7dE8aAC7d55F71853688b1F7C8F0243C85;
    uint8 constant USDC_INDEX = 0; // The index for USDC in this pool

    function run() external returns (
        address lpUsd,
        address slpUsd,
        address depositController,
        address stakingPool
    ) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        LpUSD lpUsdContract = new LpUSD(deployerAddress);
        SlpUSD slpUsdContract = new SlpUSD(deployerAddress);
        lpUsd = address(lpUsdContract);
        slpUsd = address(slpUsdContract);
        
        DepositController depositControllerContract = new DepositController(
            YVAULT_ADDRESS,
            lpUsd,
            USDC_ADDRESS,
            CURVE_POOL_ADDRESS,
            USDC_INDEX, // Pass the correct index
            deployerAddress
        );
        depositController = address(depositControllerContract);

        StakingPool stakingPoolContract = new StakingPool(lpUsd, slpUsd, deployerAddress);
        stakingPool = address(stakingPoolContract);

        depositControllerContract.setStakingPool(stakingPool);
        
        bytes32 minterRole = lpUsdContract.MINTER_ROLE();
        lpUsdContract.grantRole(minterRole, depositController);
        
        minterRole = slpUsdContract.MINTER_ROLE();
        slpUsdContract.grantRole(minterRole, stakingPool);

        lpUsdContract.renounceRole(lpUsdContract.MINTER_ROLE(), deployerAddress);
        slpUsdContract.renounceRole(slpUsdContract.MINTER_ROLE(), deployerAddress);

        vm.stopBroadcast();
    }
}