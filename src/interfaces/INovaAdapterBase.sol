// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INovaAdapterBase {
    function getAsset() external view returns (address);
    function deposit(uint256 assets) external returns (bool , uint256);
    function withdraw(uint256 shares) external returns (bool, uint256);
}