// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVelodromePair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
    function tokens() external returns (address, address);
    function getAmountOut(uint, address) external view returns (uint);
}
