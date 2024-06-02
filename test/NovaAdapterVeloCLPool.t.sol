// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NovaAdapterVeloCLPool} from "../src/adapters/NovaAdapterVeloCLPool.sol";
import {IVelodromeCLPool} from "../src/interfaces/IVelodromeCLPool.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract NovaAdapterVeloTest is Test {
    address public POOL = 0x94c0A04C0d74571aa9EE25Dd6c29E2A36f5699aE;
    address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
    NovaAdapterVeloCLPool public adapter;
    IVelodromeCLPool veloPool;
    address underlyingAddress;
    address private veloToken0;
    address private veloToken1;

    address public underlyingWhale = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

    function setUp() public {
        veloPool = IVelodromeCLPool(POOL);
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
    }

    function testDeposit() public {
        uint256 aliceUnderlyingAmount = 100 * 1e6;
        address alice = address(0xABCD);

        vm.prank(underlyingWhale);
        IERC20(underlyingAddress).transfer(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        IERC20(underlyingAddress).approve(
            address(adapter),
            aliceUnderlyingAmount
        );
        assertEq(
            IERC20(underlyingAddress).allowance(alice, address(adapter)),
            aliceUnderlyingAmount
        );

        vm.prank(alice);
        (bool success, uint256 sDaiMinted) = adapter.deposit(
            aliceUnderlyingAmount
        );

        assert(success);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), sDaiMinted);
    }

    function testWithdraw() public {
        uint256 aliceUnderlyingAmount = 100 * 1e6;
        address alice = address(0xABCD);

        vm.prank(underlyingWhale);
        IERC20(underlyingAddress).transfer(alice, aliceUnderlyingAmount);

        vm.prank(alice);
        IERC20(underlyingAddress).approve(
            address(adapter),
            aliceUnderlyingAmount
        );
        assertEq(
            IERC20(underlyingAddress).allowance(alice, address(adapter)),
            aliceUnderlyingAmount
        );

        vm.prank(alice);
        (bool succesDeposit, uint256 sDaiMinted) = adapter.deposit(
            aliceUnderlyingAmount
        );
        assert(succesDeposit);
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(sDAI).balanceOf(alice), sDaiMinted);

        vm.prank(alice);
        IERC20(sDAI).approve(address(adapter), sDaiMinted);
        vm.prank(alice);
        (bool successWithdraw, uint256 underlyingWithdrawn) = adapter.withdraw(
            sDaiMinted
        );
        assert(successWithdraw);
        assertEq(
            IERC20(underlyingAddress).balanceOf(alice),
            underlyingWithdrawn
        );
        assertEq(IERC20(sDAI).balanceOf(alice), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(address(adapter)), 0);
    }
}
