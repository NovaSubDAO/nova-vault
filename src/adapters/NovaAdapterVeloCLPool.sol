// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IVelodromeCLPool} from "../interfaces/IVelodromeCLPool.sol";
import {NovaAdapterBase} from "../NovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

contract NovaAdapterVeloCLPool is NovaAdapterBase {
    using SafeTransferLib for ERC20;

    bool private isStableFirst;
    address immutable veloToken0;
    address immutable veloToken1;

    IVelodromeCLPool immutable veloPool;

    constructor(
        address _stable,
        address _savings,
        address _pool
    ) NovaAdapterBase(_stable, _savings) {
        veloPool = IVelodromeCLPool(_pool);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();

        if ((veloToken0 == stable) && (veloToken1 == savings)) {
            isStableFirst = true;
        } else if ((veloToken0 == savings) && (veloToken1 == stable)) {
            isStableFirst = false;
        } else {
            revert("Velodrome pool should be made of `_stable` and `savings`!");
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(msg.sender == address(veloPool), "Caller is not VelodromePool");

        if (amount0Delta > 0) {
            ERC20(veloToken0).safeTransfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            ERC20(veloToken1).safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _swap(
        int256 amount,
        bool fromStableToSavings
    ) internal override returns (int256, int256) {
        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = fromStableToSavings ? 95 : 105;
        int256 sign = isStableFirst ? int256(1) : int256(-1);

        (int256 amount0, int256 amount1) = veloPool.swap(
            address(this),
            fromStableToSavings,
            sign * amount,
            (num * sqrtPriceX96) / 100,
            ""
        );

        return (amount0, amount1);
    }

    function getStable() external view returns (address) {
        return stable;
    }
}
