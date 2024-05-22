// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {ERC20} from "@solmate/tokens/ERC20.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {NovaAdapterVelo} from "../src/NovaAdapterVelo.sol";
// import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";

// contract NovaAdapterVeloTest is Test {
//     address public POOL = 0x94c0A04C0d74571aa9EE25Dd6c29E2A36f5699aE;
//     address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
//     NovaAdapterVelo public vault;
//     IVelodromePool veloPool;
//     address underlyingAddress;
//     ERC20 underlying;
//     address private veloToken0;
//     address private veloToken1;

//     address public underlyingWhale = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

//     function setUp() public {
//         veloPool = IVelodromePool(POOL);
//         veloToken0 = veloPool.token0();
//         veloToken1 = veloPool.token1();
//         if (veloToken0 == sDAI) {
//             underlyingAddress = veloToken1;
//         } else if (veloToken1 == sDAI) {
//             underlyingAddress = veloToken0;
//         } else {
//             revert("Velodrome pool should be made of `asset` and `sDAI`!");
//         }

//         underlying = ERC20(underlyingAddress);

//         vault = new NovaAdapterVelo(
//             underlying,
//             sDAI,
//             POOL,
//             "NovaAdapterVelo",
//             "NV",
//             18
//         );
//     }

//     function testDeposit() public{
//         uint256 aliceUnderlyingAmount = 100 * 1e6;
//         address alice = address(0xABCD);

//         vm.prank(underlyingWhale);
//         underlying.transfer(alice, aliceUnderlyingAmount);

//         vm.prank(alice);
//         underlying.approve(address(vault), aliceUnderlyingAmount);
//         assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

//         vm.prank(alice);
//         (bool success, uint256 sDaiMinted) = vault.deposit(aliceUnderlyingAmount);
       
//         assert(success);
//         assertEq(underlying.balanceOf(alice), 0);
//         assertEq(vault.balanceOf(alice), sDaiMinted);
//         assertEq(ERC20(sDAI).balanceOf(address(vault)), sDaiMinted);
//     }

//     function testWithdraw() public{
//         uint256 aliceUnderlyingAmount = 100 * 1e6;
//         address alice = address(0xABCD);

//         vm.prank(underlyingWhale);
//         underlying.transfer(alice, aliceUnderlyingAmount);

//         vm.prank(alice);
//         underlying.approve(address(vault), aliceUnderlyingAmount);
//         assertEq(underlying.allowance(alice, address(vault)), aliceUnderlyingAmount);

//         vm.prank(alice);
//         (bool succesDeposit, uint256 sDaiMinted) = vault.deposit(aliceUnderlyingAmount);
//         assert(succesDeposit);
//         assertEq(underlying.balanceOf(alice), 0);
//         assertEq(vault.balanceOf(alice), sDaiMinted);
//         assertEq(ERC20(sDAI).balanceOf(address(vault)), sDaiMinted);

//         vm.prank(alice);
//         (bool successWithdraw, uint256 underlyingWithdrawn) = vault.withdraw(sDaiMinted);
//         assert(successWithdraw);
//         assertEq(underlying.balanceOf(alice), underlyingWithdrawn);
//         assertEq(vault.balanceOf(alice), 0);
//         assertEq(ERC20(sDAI).balanceOf(address(vault)), 0);
//         assertEq(underlying.balanceOf(address(vault)), 0);
//     }
// }