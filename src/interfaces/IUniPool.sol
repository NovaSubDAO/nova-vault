// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}
