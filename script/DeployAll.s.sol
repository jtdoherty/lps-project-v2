// In script/DeployAll.s.sol
// FULL AND FINAL CORRECTED FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";
import "../src/mocks/MockYVault.sol";

contract DeployAll is Script {
    address constant usdcAddress = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    function run()
        external
        returns (
            address lpUsd,
            address slpUsd,
            address depositController,
            address stakingPool,
            address mockYVault
        )
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy contracts
        mockYVault = address(new MockYVault(usdcAddress));
        lpUsd = address(new LpUSD(deployerAddress));
        slpUsd = address(new SlpUSD(deployerAddress));
        depositController = address(new DepositController(
            mockYVault, lpUsd, usdcAddress, deployerAddress
        ));
        stakingPool = address(new StakingPool(
            lpUsd, slpUsd, deployerAddress
        ));

        // 2. Configure contracts
        DepositController(depositController).setStakingPool(stakingPool);

        // --- THE FIX IS HERE ---
        // We now correctly cast the address variables to their contract types
        // before calling their functions.
        bytes32 minterRole = LpUSD(lpUsd).MINTER_ROLE();
        LpUSD(lpUsd).grantRole(minterRole, depositController);

        minterRole = SlpUSD(slpUsd).MINTER_ROLE();
        SlpUSD(slpUsd).grantRole(minterRole, stakingPool);

        // 4. Renounce deployer's minting rights
        minterRole = LpUSD(lpUsd).MINTER_ROLE();
        LpUSD(lpUsd).renounceRole(minterRole, deployerAddress);

        minterRole = SlpUSD(slpUsd).MINTER_ROLE();
        SlpUSD(slpUsd).renounceRole(minterRole, deployerAddress);

        vm.stopBroadcast();
    }
}