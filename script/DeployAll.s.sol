// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";

contract DeployAll is Script {
    address testnetDai;
    address testnetYvDai;

    function run() external returns (address, address, address, address) {
        testnetDai = 0x68194A729c245035126024572c9290Cdc608A65a;
        testnetYvDai = 0x182431422FEA192383707844531317d1214227D8;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        LpUSD lpUsdToken = new LpUSD(deployer);
        SlpUSD slpUsdToken = new SlpUSD(deployer);

        DepositController controller = new DepositController(
            testnetYvDai,
            address(lpUsdToken),
            testnetDai,
            deployer // The 4th argument
        );
        StakingPool stakingPool = new StakingPool(
            address(lpUsdToken),
            address(slpUsdToken),
            deployer
        );

        // After deploying, we must link the controller to the staking pool
        controller.setStakingPool(address(stakingPool));

        lpUsdToken.grantRole(lpUsdToken.MINTER_ROLE(), address(controller));
        slpUsdToken.grantRole(slpUsdToken.MINTER_ROLE(), address(stakingPool));

        lpUsdToken.renounceRole(lpUsdToken.MINTER_ROLE(), deployer);
        slpUsdToken.renounceRole(slpUsdToken.MINTER_ROLE(), deployer);

        vm.stopBroadcast();
        
        return (
            address(lpUsdToken),
            address(slpUsdToken),
            address(controller),
            address(stakingPool)
        );
    }
}