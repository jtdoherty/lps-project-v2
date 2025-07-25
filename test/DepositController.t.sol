// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/DepositController.sol";
import "../src/tokens/LpUSD.sol";

contract DepositControllerTest is Test {
    DepositController public controller;
    LpUSD public lpUSD;
    IERC20 public daiToken;
    IYearnVault public yvDaiVault;

    // --- NEW ADDRESSES FOR DAI ---
    address constant YVDAI_VAULT = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    address constant DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USER = address(1);

    function setUp() public {
        uint256 forkBlock = 20000000;
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), forkBlock);

        daiToken = IERC20(DAI_TOKEN);
        yvDaiVault = IYearnVault(YVDAI_VAULT);

        // NOTE: We are creating "lpUSD" which is backed by DAI.
        // This is fine for a test. A real product might call it "lpDAI".
        lpUSD = new LpUSD(address(this));

        // We deploy our controller telling it about the DAI vault and token
        controller = new DepositController(
            address(yvDaiVault),
            address(lpUSD),
            address(daiToken)
        );
        lpUSD.grantRole(lpUSD.MINTER_ROLE(), address(controller));
    }

    function test_DepositAndMint_WithDAI() public {
        // DAI has 18 decimals, so 1,000 DAI is 1000 * 1e18
        uint256 initialDeposit = 1_000 * 1e18;
        
        // Magically give our test user 1,000 DAI
        deal(DAI_TOKEN, USER, initialDeposit);

        // The user deposits DAI into our controller
        vm.startPrank(USER);
        daiToken.approve(address(controller), initialDeposit);
        controller.deposit(initialDeposit);
        vm.stopPrank();

        // Check the final state
        assertEq(daiToken.balanceOf(USER), 0);
        // We need to check the lpUSD balance. But remember, our lpUSD has 6 decimals!
        // So we expect to receive 1_000 * 1e6 units of lpUSD.
        assertEq(lpUSD.balanceOf(USER), 1_000 * 1e6);
        assertTrue(IERC20(address(yvDaiVault)).balanceOf(address(controller)) > 0);
    }
}