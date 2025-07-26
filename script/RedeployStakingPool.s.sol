// In script/RedeployStakingPool.s.sol
// FULL AND COMPLETE FILE

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/StakingPool.sol";
import "../src/DepositController.sol";
import "../src/tokens/SlpUSD.sol";

contract RedeployStakingPool is Script {
    // These are the addresses from your deployment log
    address constant lpUsdAddress = 0xBC80C18E833377221709401f105FdA42553a6cab;
    address constant slpUsdAddress = 0xF16224Acdcf403Fb1DE39908cBE6B9Efa3516Ce0;
    address constant depositControllerAddress = 0x97D3D998e4d05a5b22a31D01Ff066Dd9890Ce205;
    
    // This is your OLD, broken staking pool. We need to revoke its role.
    address constant oldStakingPoolAddress = 0xF9827Be4443776Dd0e349c1978934EDf0b74fbe7;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the new, corrected StakingPool
        StakingPool newStakingPool = new StakingPool(lpUsdAddress, slpUsdAddress, deployerAddress);
        console.log("New StakingPool deployed at:", address(newStakingPool));

        // 2. Point the DepositController to the NEW StakingPool
        DepositController controller = DepositController(depositControllerAddress);
        controller.setStakingPool(address(newStakingPool));
        console.log("DepositController updated to use new StakingPool.");

        // 3. Grant MINTER_ROLE to the NEW StakingPool
        SlpUSD slp = SlpUSD(slpUsdAddress);
        bytes32 minterRole = slp.MINTER_ROLE();
        slp.grantRole(minterRole, address(newStakingPool));
        console.log("MINTER_ROLE granted to new StakingPool.");
        
        // 4. (Good Practice) Revoke MINTER_ROLE from the OLD StakingPool
        slp.revokeRole(minterRole, oldStakingPoolAddress);
        console.log("MINTER_ROLE revoked from old StakingPool.");

        vm.stopBroadcast();
    }
}