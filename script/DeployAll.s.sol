// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DepositController.sol";
import "../src/StakingPool.sol";
import "../src/tokens/LpUSD.sol";
import "../src/tokens/SlpUSD.sol";
import "../src/mocks/MockYVault.sol";

contract DeployAll is Script {
    // --- THIS IS THE FIX ---
    // Using the correctly checksummed address for Sepolia USDC.
    address testnetUsdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    
    address mockYvUsdc;

    function run() external returns (address, address, address, address, address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy our Mock Vault first, telling it where the testnet USDC token is.
        MockYVault mockVault = new MockYVault(testnetUsdc);
        mockYvUsdc = address(mockVault);

        // 2. Deploy the tokens
        LpUSD lpUsdToken = new LpUSD(deployer);
        SlpUSD slpUsdToken = new SlpUSD(deployer);

        // 3. Deploy the main contracts
        DepositController controller = new DepositController(
            mockYvUsdc,
            address(lpUsdToken),
            testnetUsdc,
            deployer // Owner
        );
        StakingPool stakingPool = new StakingPool(
            address(lpUsdToken),
            address(slpUsdToken),
            deployer // Owner
        );

        // 4. Wire everything together
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
            address(stakingPool),
            mockYvUsdc
        );
    }
}