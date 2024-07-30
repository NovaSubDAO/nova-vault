// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NovaVaultV2} from "../src/NovaVaultV2.sol";
import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {GenericSwapFacet} from "@lifi/src/Facets/GenericSwapFacet.sol";

contract NovaVaultV2Test is Test {
    address public USDC_SDAI_POOL = 0x131525f3FA23d65DC2B1EB8B6483a28c43B06916;
    address public USDC_USDT_POOL = 0x84Ce89B4f6F67E523A81A82f9f2F14D84B726F6B;
    address public sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
    address public usdc = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    NovaVaultV2 public vault;
    GenericSwapFacet public swapFacet;
    IVelodromePool veloPool;
    IVelodromePool veloPool_2;
    address private veloToken0;
    address private veloToken1;
    address underlyingAddress;
    uint256 aliceUnderlyingAmount = 100 * 1e6;
    address alice = address(0xABCD);
    uint256 bobUnderlyingAmount = 80 * 1e6;
    address bob = address(0xBCDE);
    address[] stables;
    address[] novaAdapters;

    address public underlyingWhale = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;

    function setUp() public {
        veloPool = IVelodromePool(USDC_SDAI_POOL);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();

        swapFacet = new GenericSwapFacet();

        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        vault = new NovaVaultV2(sDAI, address(swapFacet));
        vault.addDex(address(veloPool));
        vault.setFunctionApprovalBySignature(veloPool.swap.selector);
    }

    function testNovaVaultV2SingleDeposit() public {
        bool fromStableTosDai = true;
        bool isStableFirst = true;

        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromStableTosDai ? 95 : 105;
        int256 sign = isStableFirst ? int256(1) : int256(-1);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            underlyingAddress,
            sDAI,
            aliceUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(aliceUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

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

        vm.prank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            swapData,
            111
        );

        assert(successDeposit);
        assertEq(sDaiAmount, IERC20(sDAI).balanceOf(alice));
    }

    function testNovaVaultV2SingleDepositAndWithdraw() public {
        bool fromStableTosDai = true;
        bool isStableFirst = true;

        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromStableTosDai ? 95 : 105;
        int256 sign = isStableFirst ? int256(1) : int256(-1);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            underlyingAddress,
            sDAI,
            aliceUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(aliceUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

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

        vm.prank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            swapData,
            111
        );

        assert(successDeposit);
        assertEq(sDaiAmount, IERC20(sDAI).balanceOf(alice));

        fromStableTosDai = false;
        num = fromStableTosDai ? 95 : 105;

        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            sDAI,
            underlyingAddress,
            sDaiAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(sDaiAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

        vm.prank(alice);
        IERC20(sDAI).approve(address(vault), sDaiAmount);
        assertEq(IERC20(sDAI).allowance(alice, address(vault)), sDaiAmount);

        vm.prank(alice);
        (bool successWithdraw, uint256 underlyingAmount) = vault.withdraw(
            111,
            swapData
        );

        assert(successWithdraw);
        assertEq(underlyingAmount, IERC20(underlyingAddress).balanceOf(alice));
    }

    function testNovaVaultV2TwoDepositsOneWithdraw() public {
        bool fromStableTosDai = true;
        bool isStableFirst = true;

        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromStableTosDai ? 95 : 105;
        int256 sign = isStableFirst ? int256(1) : int256(-1);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            underlyingAddress,
            sDAI,
            aliceUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(aliceUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

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

        vm.prank(alice);
        (bool successFirstDeposit, uint256 sDaiFirstAmount) = vault.deposit(
            swapData,
            111
        );

        assert(successFirstDeposit);
        assertEq(sDaiFirstAmount, IERC20(sDAI).balanceOf(alice));

        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            underlyingAddress,
            sDAI,
            bobUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(bobUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

        vm.prank(underlyingWhale);
        IERC20(underlyingAddress).transfer(bob, bobUnderlyingAmount);

        vm.prank(bob);
        IERC20(underlyingAddress).approve(address(vault), bobUnderlyingAmount);
        assertEq(
            IERC20(underlyingAddress).allowance(bob, address(vault)),
            bobUnderlyingAmount
        );

        vm.prank(bob);
        (bool successSecondDeposit, uint256 sDaiSecondAmount) = vault.deposit(
            swapData,
            222
        );

        assert(successSecondDeposit);
        assertEq(sDaiSecondAmount, IERC20(sDAI).balanceOf(bob));

        fromStableTosDai = false;
        num = fromStableTosDai ? 95 : 105;

        swapData[0] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            sDAI,
            underlyingAddress,
            sDaiSecondAmount,
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(sDaiSecondAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

        vm.prank(alice);
        IERC20(sDAI).approve(address(vault), sDaiSecondAmount);
        assertEq(
            IERC20(sDAI).allowance(alice, address(vault)),
            sDaiSecondAmount
        );

        vm.prank(alice);
        (bool successWithdraw, uint256 underlyingAmount) = vault.withdraw(
            111,
            swapData
        );

        assert(successWithdraw);
        assertEq(underlyingAmount, IERC20(underlyingAddress).balanceOf(alice));
    }

    function testDoubleDepositShouldWork() public {
        veloPool_2 = IVelodromePool(USDC_USDT_POOL);

        veloToken0 = veloPool_2.token0();
        veloToken1 = veloPool_2.token1();

        if (veloToken0 == usdc) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == usdc) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        vault.addDex(address(veloPool_2));
        vault.setFunctionApprovalBySignature(veloPool_2.swap.selector);

        bool fromUsdcToUsdt = false;
        bool isUsdcFirst = true;

        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromUsdcToUsdt ? 95 : 105;
        int256 sign = isUsdcFirst ? int256(1) : int256(-1);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](2);
        swapData[0] = LibSwap.SwapData(
            address(veloPool_2),
            address(veloPool_2),
            underlyingAddress,
            usdc,
            aliceUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool_2.swap.selector,
                address(vault),
                fromUsdcToUsdt,
                sign * int256(aliceUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

        bool fromStableTosDai = true;
        bool isStableFirst = true;

        (sqrtPriceX96, , , , , ) = veloPool.slot0();
        num = fromStableTosDai ? 95 : 105;
        sign = isStableFirst ? int256(1) : int256(-1);

        swapData[1] = LibSwap.SwapData(
            address(veloPool),
            address(veloPool),
            usdc,
            sDAI,
            aliceUnderlyingAmount - 10000, //To change !
            abi.encodeWithSelector(
                veloPool.swap.selector,
                address(vault),
                fromStableTosDai,
                sign * int256(aliceUnderlyingAmount - 10000), //To change !
                (num * sqrtPriceX96) / 100,
                ""
            ),
            false
        );

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

        vm.prank(alice);
        (bool successDeposit, uint256 sDaiAmount) = vault.deposit(
            swapData,
            111
        );

        assert(successDeposit);
        assertEq(sDaiAmount, IERC20(sDAI).balanceOf(alice));
        assertEq(IERC20(underlyingAddress).balanceOf(alice), 0);
        assertEq(IERC20(underlyingAddress).balanceOf(address(vault)), 0);
        assert(IERC20(usdc).balanceOf(address(vault)) < 1000); // To change !
    }

    function testNovaVaultV2DepositFails() public {
        veloPool_2 = IVelodromePool(USDC_USDT_POOL);

        veloToken0 = veloPool_2.token0();
        veloToken1 = veloPool_2.token1();

        if (veloToken0 == usdc) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == usdc) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        vault.addDex(address(veloPool_2));
        vault.setFunctionApprovalBySignature(veloPool_2.swap.selector);

        bool fromUsdcToUsdt = false;
        bool isUsdcFirst = true;

        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromUsdcToUsdt ? 95 : 105;
        int256 sign = isUsdcFirst ? int256(1) : int256(-1);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData(
            address(veloPool_2),
            address(veloPool_2),
            underlyingAddress,
            usdc,
            aliceUnderlyingAmount,
            abi.encodeWithSelector(
                veloPool_2.swap.selector,
                address(vault),
                fromUsdcToUsdt,
                sign * int256(aliceUnderlyingAmount),
                (num * sqrtPriceX96) / 100,
                ""
            ),
            true
        );

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

        vm.prank(alice);
        vm.expectRevert(NovaVaultV2.InvalidAssetId.selector);
        vault.deposit(swapData, 111);
    }
}
