// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";

contract DeployAll is Script {
    // --- THIS IS THE FIX ---
    // We declare the variables here but assign them in run() to avoid checksum issues.
    address testnetDai;
    address testnetYvDai;

    function run() external returns (address, address, address, address) {
        // We assign the correctly checksummed addresses inside the function.
        testnetDai = 0x68194A729c245035126024572c9290Cdc608A65a; // Sepolia DAI
        testnetYvDai = 0x182431422FEA192383707844531317d1214227D8; // Placeholder Vault

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the tokens
        LpUSD lpUsdToken = new LpUSD(deployer);
        SlpUSD slpUsdToken = new SlpUSD(deployer);

        // 2. Deploy the main contracts
        DepositController controller = new DepositController(
            testnetYvDai,
            address(lpUsdToken),
            testnetDai
        );
        StakingPool stakingPool = new StakingPool(
            address(lpUsdToken),
            address(slpUsdToken),
            deployer // We make the deployer the owner
        );

        // 3. Grant the necessary roles to the contracts
        lpUsdToken.grantRole(lpUsdToken.MINTER_ROLE(), address(controller));
        slpUsdToken.grantRole(slpUsdToken.MINTER_ROLE(), address(stakingPool));

        // 4. Renounce deployer's temporary minter roles for security
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