// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {NovaVault} from "../src/NovaVault.sol";
import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";

contract NovaVaultTest is Test {
    address public POOL = 0x94c0A04C0d74571aa9EE25Dd6c29E2A36f5699aE;
    address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
    NovaVault public vault;
    IVelodromePool veloPool;
    address underlyingAddress;
    ERC20 underlying;
    address private veloToken0;
    address private veloToken1;

    address public underlyingWhale = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

    function setUp() public {
        veloPool = IVelodromePool(POOL);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();

        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        underlying = ERC20(underlyingAddress);

        vault = new NovaVault(
            underlying,
            POOL,
            sDAI,
            "NovaVault",
            "NV"
        );
    }


    function testSingleDepositWithdraw() public {
        uint256 aliceUnderlyingAmount = 1_000 * 1e6;

        address alice = address(0xABCD);
        vm.prank(underlyingWhale);
        underlying.transfer(alice, aliceUnderlyingAmount); 


        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice); 

        // Expect exchange rate to be 1:1 on initial deposit.
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.totalSupply(), aliceShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);
        
        console.log("Alice balance on Underlying before withdraw: ", underlying.balanceOf(alice));
        console.log("Alice balance on Vault before withdraw: ", vault.balanceOf(alice));
        console.log("aliceUnderlyingAmount: ", aliceUnderlyingAmount);
        console.log("Vault Total Assets before withdraw: ",vault.totalAssets());
       
        uint256 withdrawValue = (50 * vault.balanceOf(alice)) / 100;

        vm.prank(alice);
        vault.withdraw(withdrawValue, alice, alice);
        console.log("Alice balance on vault after withdraw: ", vault.balanceOf(alice));
        console.log("Vault Total Assets after withdraw: ", vault.totalAssets());

        assertEq(vault.totalSupply(), aliceShareAmount - withdrawValue);
        assertEq(vault.balanceOf(alice), aliceShareAmount - withdrawValue);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount - withdrawValue);
        assertEq(underlying.balanceOf(alice), withdrawValue);
        
        // assertEq(vault.totalAssets(), 0);
        // assertEq(vault.balanceOf(alice), 0);
        // assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        // assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }

    function testTwoDepositsSingleWithdraw() public {
        uint256 aliceUnderlyingAmount = 1_000 * 1e6;
        uint256 bobUnderlyingAmount = 1_200 * 1e6;

        address alice = address(0xABCD);
        address bob = address(0xBCDE);

        vm.prank(underlyingWhale);
        underlying.transfer(alice, aliceUnderlyingAmount);

        vm.prank(underlyingWhale); 
        underlying.transfer(bob, bobUnderlyingAmount);

        vm.prank(alice);
        underlying.approve(address(vault), aliceUnderlyingAmount);
        assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

        vm.prank(bob);
        underlying.approve(address(vault), bobUnderlyingAmount);
        assertEq(underlying.allowance(bob, address(vault)), bobUnderlyingAmount);

        uint256 alicePreDepositBal = underlying.balanceOf(alice);
        uint256 bobPreDepositBal = underlying.balanceOf(bob);

        vm.prank(alice);
        uint256 aliceShareAmount = vault.deposit(aliceUnderlyingAmount, alice);

        vm.prank(bob);
        uint256 bobShareAmount = vault.deposit(bobUnderlyingAmount, bob);

        // Expect exchange rate to be 1:1 on initial deposit.
        assertEq(aliceUnderlyingAmount, aliceShareAmount);
        assertEq(vault.previewWithdraw(aliceShareAmount), aliceUnderlyingAmount);
        assertEq(vault.previewDeposit(aliceUnderlyingAmount), aliceShareAmount);
        assertEq(vault.balanceOf(alice), aliceShareAmount);
        assertEq(underlying.balanceOf(alice), alicePreDepositBal - aliceUnderlyingAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount);

        assertEq(bobUnderlyingAmount, bobShareAmount);
        assertEq(vault.previewWithdraw(bobShareAmount), bobUnderlyingAmount);
        assertEq(vault.previewDeposit(bobUnderlyingAmount), bobShareAmount);
        assertEq(vault.balanceOf(bob), bobShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), bobUnderlyingAmount);
        assertEq(underlying.balanceOf(bob), bobPreDepositBal - bobUnderlyingAmount);
        
        assertEq(vault.totalSupply(), aliceShareAmount + bobShareAmount);
        assertEq(vault.totalAssets(), aliceUnderlyingAmount + bobUnderlyingAmount);

        console.log("Alice balance on Underlying: ", underlying.balanceOf(alice));
        console.log("Alice balance on Vault: ", vault.balanceOf(alice));
        console.log("aliceUnderlyingAmount: ", aliceUnderlyingAmount);

        console.log("bob balance on Underlying: ", underlying.balanceOf(bob));
        console.log("bob balance on Vault: ", vault.balanceOf(bob));
        console.log("bobUnderlyingAmount: ", bobUnderlyingAmount);

        console.log("Vault Total Assets before withdraw: ",vault.totalAssets());

        uint256 withdrawValue = (50 * vault.balanceOf(alice)) / 100;
       
        vm.prank(alice);
        vault.withdraw(withdrawValue, alice, alice);
        console.log("Vault Total Assets after withdraw: ",vault.totalAssets());

        assertEq(vault.totalSupply(), aliceShareAmount + bobShareAmount - withdrawValue);
        assertEq(vault.balanceOf(alice), aliceShareAmount - withdrawValue);
        assertEq(vault.convertToAssets(vault.balanceOf(alice)), aliceUnderlyingAmount - withdrawValue);
        assertEq(underlying.balanceOf(alice), withdrawValue);

        assertEq(vault.balanceOf(bob), bobShareAmount);
        assertEq(vault.convertToAssets(vault.balanceOf(bob)), bobUnderlyingAmount);
        assertEq(underlying.balanceOf(bob), bobUnderlyingAmount - bobShareAmount);
    }
}
