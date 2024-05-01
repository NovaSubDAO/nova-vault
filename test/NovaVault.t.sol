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
        uint256 aliceUnderlyingAmount = 100 * 1e10;

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
        
        console.log("Alice balance on Underlying: ", underlying.balanceOf(alice));
        console.log("Alice balance on Vault: ", vault.balanceOf(alice));
        console.log("aliceUnderlyingAmount: ", aliceUnderlyingAmount);
        console.log("Vault Total Asset before withdraw: ",vault.totalAssets());
       
        vm.prank(alice);
        vault.withdraw(7e11, alice, alice);
        console.log("Alice balance on Vault: ", vault.balanceOf(alice));
        console.log("Vault Total Asset after withdraw: ",vault.totalAssets());

        // assertEq(vault.totalAssets(), 0);
        // assertEq(vault.balanceOf(alice), 0);
        // assertEq(vault.convertToAssets(vault.balanceOf(alice)), 0);
        // assertEq(underlying.balanceOf(alice), alicePreDepositBal);
    }
}
