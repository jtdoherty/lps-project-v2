// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DepositController.sol";
import "../src/tokens/LpUSD.sol";
import "../src/mocks/MockYVault.sol";
import "../src/mocks/MockERC20.sol";

contract DepositControllerTest is Test {
    DepositController public controller;
    LpUSD public lpUSD;
    MockERC20 public underlyingToken;
    MockYVault public mockVault;

    address user = address(1);
    address deployer = address(this);

    function setUp() public {
        underlyingToken = new MockERC20("Mock DAI", "mDAI");
        mockVault = new MockYVault(address(underlyingToken));
        lpUSD = new LpUSD(deployer);

        controller = new DepositController(
            address(mockVault),
            address(lpUSD),
            address(underlyingToken),
            deployer // The 4th argument
        );
        
        lpUSD.grantRole(lpUSD.MINTER_ROLE(), address(controller));
    }

    function test_DepositAndRedeem_FullCycle_WithMock() public {
        uint256 initialDeposit = 10_000 * 1e18;
        
        underlyingToken.mint(user, initialDeposit);
        vm.startPrank(user);
        underlyingToken.approve(address(controller), initialDeposit);
        controller.deposit(initialDeposit);
        vm.stopPrank();
        
        uint256 expectedLpUsd = 10_000 * 1e6;
        assertEq(lpUSD.balanceOf(user), expectedLpUsd);

        vm.startPrank(user);
        lpUSD.approve(address(controller), expectedLpUsd);
        controller.redeem(expectedLpUsd);
        vm.stopPrank();

        assertEq(lpUSD.balanceOf(user), 0);
        assertEq(underlyingToken.balanceOf(user), initialDeposit);
    }
}