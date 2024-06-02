// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IVelodromePool} from "../interfaces/IVelodromePool.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {NovaAdapterBase} from "../NovaAdapterBase.sol";

contract NovaAdapterVeloPool is NovaAdapterBase {
    bool private isStableFirst;
    address immutable veloToken0;
    address immutable veloToken1;

    IVelodromePool public veloPool;

    constructor(
        address _asset,
        address _sDAI,
        address _pool
    ) NovaAdapterBase(_asset, _sDAI) {
        veloPool = IVelodromePool(_pool);
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
        int256 amount,
        bool fromStableTosDai
    ) internal override returns (int256, int256) {
        uint256 amount0Out = 0;
        uint256 amount1Out = 0;

        if (fromStableTosDai) {
            IERC20(asset).transfer(address(veloPool), uint256(amount));
            amount1Out = veloPool.getAmountOut(uint256(amount), asset);
            veloPool.swap(0, amount1Out, address(this), "");
        } else {
            IERC20(sDAI).transfer(address(veloPool), uint256(amount));
            amount0Out = veloPool.getAmountOut(uint256(amount), sDAI);
            veloPool.swap(amount0Out, 0, address(this), "");
        }

        return (int256(amount0Out), int256(amount1Out));
    }

    function getAsset() external view returns (address) {
        return asset;
    }
}
