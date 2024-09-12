// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface INovaAdapterBase {
    function getStable() external view returns (address);
    function deposit(uint256 stable) external returns (bool, uint256);
    function withdraw(uint256 shares) external returns (bool, uint256);
}
