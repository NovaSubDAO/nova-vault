// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IVelodromePoolB} from "./interfaces/IVelodromePoolB.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {NovaAdapterBase} from "./NovaAdapterBase.sol";

contract NovaAdapterVeloB is NovaAdapterBase {
    bool private isStableFirst;
    address immutable veloToken0;
    address immutable veloToken1;

    IVelodromePoolB public veloPool;

    constructor(
        address _asset,
        address _sDAI,
        address _pool
    ) NovaAdapterBase(_asset, _sDAI) {
        veloPool = IVelodromePoolB(_pool);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();

        if ((veloToken0 == asset) && (veloToken1 == sDAI)) {
            isStableFirst = true;
        } else if ((veloToken0 == sDAI) && (veloToken1 == asset)) {
            isStableFirst = false;
        } else {
            revert("Velodrome pool should be made of `_asset` and `sDAI`!");
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(msg.sender == address(veloPool), "Caller is not VelodromePool");

        if (amount0Delta > 0) {
            IERC20(veloToken0).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(veloToken1).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal override returns (int256) {
        veloPool.swap(amount0Out, amount1Out, to, "");

        return int256(veloPool.getAmountOut(amount0Out, veloToken0));
    }

    function getAsset() external view returns (address) {
        return asset;
    }
}
