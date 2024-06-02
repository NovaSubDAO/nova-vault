// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NovaVault} from "../src/NovaVault.sol";
import {NovaAdapterVeloCLPool} from "../src/adapters/NovaAdapterVeloCLPool.sol";
import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract NovaVaultTest is Test {
    address public POOL = 0x94c0A04C0d74571aa9EE25Dd6c29E2A36f5699aE;
    address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
    NovaAdapterVeloCLPool public adapter;
    NovaVault public vault;
    IVelodromePool veloPool;
    address underlyingAddress;
    address private veloToken0;
    address private veloToken1;
    address[] stables;
    address[] novaAdapters;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

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

        adapter = new NovaAdapterVeloCLPool(underlyingAddress, sDAI, POOL);

        stables.push(underlyingAddress);
        novaAdapters.push(address(adapter));

        vault = new NovaVault(sDAI, stables, novaAdapters);
    }

    function testNovaVaultDepositAndWithdraw() public {
        uint256 aliceUnderlyingAmount = 100 * 1e6;
        address alice = address(0xABCD);

        vm.prank(underlyingWhale);
        IERC20(underlyingAddress).transfer(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        IERC20(underlyingAddress).approve(
            address(vault),
            aliceUnderlyingAmount
        );
        assertEq(
            IERC20(underlyingAddress).allowance(alice, address(vault)),
            aliceUnderlyingAmount
        );

        vm.expectEmit(address(vault));
        emit Referral(111, alice, aliceUnderlyingAmount);

        vm.prank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            underlyingAddress,
            aliceUnderlyingAmount,
            111
        );
        assert(successDeposit);
        assertEq(IERC20(underlyingAddress).allowance(alice, address(vault)), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), sDaiAmount);

        vm.prank(alice);
        IERC20(sDAI).approve(address(vault), sDaiAmount);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), sDaiAmount);

        vm.prank(alice);
        (bool successWithdraw, uint256 assetsAmount) = vault.withdraw(
            underlyingAddress,
            sDaiAmount
        );
        assert(successWithdraw);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), assetsAmount);
    }
}
