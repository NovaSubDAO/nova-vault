// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {console} from "forge-std/console.sol";

abstract contract NovaAdapterBase is ERC20 {

    error TransferFailed(
        address sender,
        address recipient,
        uint256 amount
    );

    address immutable sDAI;
    ERC20 asset;

    constructor(
        ERC20 _asset,
        address _sDAI,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        asset = _asset;
        sDAI = _sDAI;
    }

    function deposit(uint256 assets) external returns (uint256) {
        // bool success = asset.transferFrom(msg.sender, address(this), assets);
        // if(!success){
        //     revert TransferFailed(msg.sender, address(this), assets);
        // }

        (, int256 sDai) = _swap(int256(assets), true);
        uint256 sDaiToMint = uint256(-sDai);

        _mint(msg.sender, sDaiToMint);

        return sDaiToMint;
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        (int256 assets, ) = _swap(int256(shares), false);
        uint256 assetsToTransfer = uint256(-assets);

        bool success = asset.transfer(msg.sender, assetsToTransfer);
        if(!success){
            revert TransferFailed(msg.sender, address(this), assetsToTransfer);
        }

        _burn(msg.sender, shares);

        return (true, assetsToTransfer);
    }

    /**
     * @notice Performs a swap operation between the stable asset and sDAI.
     * @dev This function interacts with the pool to execute the swap.
     * @param amount The amount to be swapped.
     * @param fromStableTosDai A boolean indicating the direction of the swap. 
     *                         - `true` for swapping from the stable asset to sDAI.
     *                         - `false` for swapping from sDAI to the stable asset.
     * @return amount0 The amount of token0 involved in the swap.
     * @return amount1 The amount of token1 involved in the swap.
     */
    function _swap(
        int256 amount,
        bool fromStableTosDai
    ) internal virtual returns (int256, int256);
}