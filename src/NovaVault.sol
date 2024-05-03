// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC4626} from "@solmate/tokens/ERC4626.sol";
import {IVelodromePool} from "src/interfaces/IVelodromePool.sol";
import {console} from "forge-std/Test.sol";

contract NovaVault is ERC4626 {
    IVelodromePool public veloPool;
    bool private isStableFirst;
    address private veloToken0;
    address private veloToken1;
    address public sDAI;

    event Comparison(uint256 left, uint256 right);

    constructor(
        ERC20 _asset,
        address _pool,
        address _sDAI,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) {
        veloPool = IVelodromePool(_pool);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();
        sDAI = _sDAI;

        if ((veloToken0 == address(_asset)) && (veloToken1 == sDAI)) {
            isStableFirst = true;
        } else if ((veloToken0 == sDAI) && (veloToken1 == address(_asset))) {
            isStableFirst = false;
        } else {
            revert("Velodrome pool should be made of `_asset` and `sDAI`!");
        }
    }

    function totalAssets() public view override returns (uint256) {
        return totalSupply;
    }

    function afterDeposit(uint256 assets, uint256) internal override {
        asset.approve(address(veloPool), assets);
        _swap(int256(assets), true);
    }

    function beforeWithdraw(uint256, uint256 shares) internal override {
        uint256 assets = convertToAssets(shares);
        ERC20(sDAI).approve(address(veloPool), assets);

        uint256 balanceSDAI = ERC20(sDAI).balanceOf(address(this));
        emit Comparison(shares, balanceSDAI);

        _swap(int256(assets), false);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(msg.sender == address(veloPool), "Caller is not VelodromePool");
        if (amount0Delta > 0) {
            ERC20(veloToken0).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            ERC20(veloToken1).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _swap(
        int256 amount,
        bool fromStableTosDai
    ) internal {
        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = isStableFirst ? 95 : 105;
        int8 sign = fromStableTosDai ? int8(1) : int8(-1);
        veloPool.swap(
            address(this),
            isStableFirst,
            sign * amount,
            (num * sqrtPriceX96) / 100,
            ""
        );
    }
}
