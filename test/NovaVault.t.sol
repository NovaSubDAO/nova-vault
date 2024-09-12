// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {NovaVault} from "../src/NovaVault.sol";
import {NovaAdapterVeloCLPool} from "../src/adapters/NovaAdapterVeloCLPool.sol";
import {IVelodromeCLPool} from "../src/interfaces/IVelodromeCLPool.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract NovaVaultTest is Test {
    address public CLPOOL_1 = 0x131525f3FA23d65DC2B1EB8B6483a28c43B06916;
    address public CLPOOL_2 = 0x94c0A04C0d74571aa9EE25Dd6c29E2A36f5699aE;
    address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
    NovaAdapterVeloCLPool public adapterCLPoolFirst;
    NovaVault public vault;
    IVelodromeCLPool veloCLPoolFirst;
    address underlyingAddress;
    address private veloToken0;
    address private veloToken1;
    address[] stables;
    address[] novaAdapters;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);
    address public owner = address(0x1234);
    uint256 aliceUnderlyingAmount = 100 * 1e6;
    address alice = address(0xABCD);

    address public underlyingWhale = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

    modifier transferAndApproveUnderlying() {
        vm.prank(underlyingWhale);
        IERC20(underlyingAddress).transfer(alice, aliceUnderlyingAmount);

        vm.startPrank(alice);
        IERC20(underlyingAddress).approve(
            address(vault),
            aliceUnderlyingAmount
        );
        assertEq(
            IERC20(underlyingAddress).allowance(alice, address(vault)),
            aliceUnderlyingAmount
        );
        vm.stopPrank();
        _;
    }

    function setUp() public {
        veloCLPoolFirst = IVelodromeCLPool(CLPOOL_1);
        veloToken0 = veloCLPoolFirst.token0();
        veloToken1 = veloCLPoolFirst.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        adapterCLPoolFirst = new NovaAdapterVeloCLPool(
            underlyingAddress,
            sDAI,
            CLPOOL_1
        );

        stables.push(underlyingAddress);
        novaAdapters.push(address(adapterCLPoolFirst));

        vm.prank(owner);
        vault = new NovaVault(sDAI, stables, novaAdapters);
    }

    function testNovaVaultDepositAndWithdraw()
        public
        transferAndApproveUnderlying
    {
        vm.expectEmit(address(vault));
        emit Referral(111, alice, aliceUnderlyingAmount);

        vm.startPrank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            underlyingAddress,
            aliceUnderlyingAmount,
            111
        );
        assert(successDeposit);
        assertEq(IERC20(underlyingAddress).allowance(alice, address(vault)), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), sDaiAmount);

        IERC20(sDAI).approve(address(vault), sDaiAmount);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), sDaiAmount);

        vm.expectEmit(address(vault));
        emit Referral(111, alice, sDaiAmount);

        (bool successWithdraw, uint256 assetsAmount) = vault.withdraw(
            underlyingAddress,
            sDaiAmount,
            111
        );
        assert(successWithdraw);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), assetsAmount);
        vm.stopPrank();
    }

    function testNovaVaultReplaceAdapter() public transferAndApproveUnderlying {
        IVelodromeCLPool veloCLPoolSecond = IVelodromeCLPool(CLPOOL_2);
        veloToken0 = veloCLPoolSecond.token0();
        veloToken1 = veloCLPoolSecond.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        NovaAdapterVeloCLPool adapterCLPoolSecond = new NovaAdapterVeloCLPool(
            underlyingAddress,
            sDAI,
            CLPOOL_2
        );

        assertEq(
            vault._novaAdapters(underlyingAddress),
            address(adapterCLPoolFirst)
        );

        vm.prank(owner);
        vault.replaceAdapter(underlyingAddress, address(adapterCLPoolSecond));

        assertEq(
            vault._novaAdapters(underlyingAddress),
            address(adapterCLPoolSecond)
        );

        vm.expectEmit(address(vault));
        emit Referral(111, alice, aliceUnderlyingAmount);

        vm.startPrank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            underlyingAddress,
            aliceUnderlyingAmount,
            111
        );
        assert(successDeposit);
        assertEq(IERC20(underlyingAddress).allowance(alice, address(vault)), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), sDaiAmount);

        IERC20(sDAI).approve(address(vault), sDaiAmount);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), sDaiAmount);

        vm.expectEmit(address(vault));
        emit Referral(111, alice, sDaiAmount);

        (bool successWithdraw, uint256 assetsAmount) = vault.withdraw(
            underlyingAddress,
            sDaiAmount,
            111
        );
        assert(successWithdraw);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), assetsAmount);
        assertEq(
            vault._novaAdapters(underlyingAddress),
            address(adapterCLPoolSecond)
        );
        vm.stopPrank();
    }

    function testNovaVaultCallerIsNotTheOwner() public {
        IVelodromeCLPool veloCLPoolSecond = IVelodromeCLPool(CLPOOL_2);
        veloToken0 = veloCLPoolSecond.token0();
        veloToken1 = veloCLPoolSecond.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        NovaAdapterVeloCLPool adapterCLPoolSecond = new NovaAdapterVeloCLPool(
            underlyingAddress,
            sDAI,
            CLPOOL_2
        );

        assertEq(
            vault._novaAdapters(underlyingAddress),
            address(adapterCLPoolFirst)
        );

        vm.expectRevert();
        vault.replaceAdapter(underlyingAddress, address(adapterCLPoolSecond));
    }

    function testNovaVaultOnlyNonZero() public {
        vm.expectRevert();
        vm.prank(owner);
        vault = new NovaVault(address(0), stables, novaAdapters);
    }

    function testNovaVaultOnlyApprovedAdapter()
        public
        transferAndApproveUnderlying
    {
        address nonApprovedStable = 0x84Ce89B4f6F67E523A81A82f9f2F14D84B726F6B;
        vm.startPrank(alice);
        vm.expectRevert(Errors.NO_ADAPTER_APPROVED.selector);
        vault.deposit(nonApprovedStable, aliceUnderlyingAmount, 111);

        vm.expectRevert(Errors.NO_ADAPTER_APPROVED.selector);
        vault.withdraw(nonApprovedStable, aliceUnderlyingAmount, 111);
        vm.stopPrank();
    }

    function testNovaVaultAdapterAlreadyApproved() public {
        vm.prank(owner);
        vm.expectRevert(Errors.ADAPTER_ALREADY_APPROVED.selector);
        vault.replaceAdapter(underlyingAddress, address(adapterCLPoolFirst));
    }

    function testNovaVaultMismatchingArraysLength() public {
        veloCLPoolFirst = IVelodromeCLPool(CLPOOL_1);
        veloToken0 = veloCLPoolFirst.token0();
        veloToken1 = veloCLPoolFirst.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        address secondStable = 0x84Ce89B4f6F67E523A81A82f9f2F14D84B726F6B;

        adapterCLPoolFirst = new NovaAdapterVeloCLPool(
            underlyingAddress,
            sDAI,
            CLPOOL_1
        );

        stables.push(underlyingAddress);
        stables.push(secondStable);
        novaAdapters.push(address(adapterCLPoolFirst));

        vm.prank(owner);
        vm.expectRevert(Errors.MISMATCHING_ARRAYS_LENGTH.selector);
        vault = new NovaVault(sDAI, stables, novaAdapters);
    }

    function testNovaVaultInvalidStableToAdapterMapping() public {
        IVelodromeCLPool veloCLPoolSecond = IVelodromeCLPool(CLPOOL_2);
        veloToken0 = veloCLPoolSecond.token0();
        veloToken1 = veloCLPoolSecond.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        NovaAdapterVeloCLPool adapterCLPoolSecond = new NovaAdapterVeloCLPool(
            underlyingAddress,
            sDAI,
            CLPOOL_2
        );

        address invalidStable = 0x84Ce89B4f6F67E523A81A82f9f2F14D84B726F6B;

        vm.prank(owner);
        vm.expectRevert();
        vault.replaceAdapter(invalidStable, address(adapterCLPoolSecond));
    }
}
