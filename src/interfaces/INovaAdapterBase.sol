// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";

interface INovaAdapterBase {
    ERC20 asset;

    function deposit(uint256 assets) external returns (bool , uint256);

    function withdraw(uint256 shares) external returns (bool, uint256);
}