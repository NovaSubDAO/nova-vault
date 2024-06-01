// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVelodromePoolB {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256);
}