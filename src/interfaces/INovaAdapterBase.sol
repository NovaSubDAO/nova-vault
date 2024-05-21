// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";

interface INovaAdapterBase {
    function getAsset() external view returns (ERC20);
    function deposit(uint256 assets) external returns (bool , uint256);
    function withdraw(uint256 shares) external returns (bool, uint256);
}