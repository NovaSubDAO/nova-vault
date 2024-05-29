// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "./interfaces/IERC20.sol";

abstract contract NovaAdapterBase {
    error TransferFailed(address sender, address recipient, uint256 amount);

    address immutable sDAI;
    address immutable asset;

    constructor(address _asset, address _sDAI) {
        asset = _asset;
        sDAI = _sDAI;
    }

    function deposit(uint256 assets) external returns (bool, uint256) {
        bool successFirst = IERC20(asset).transferFrom(
            msg.sender,
            address(this),
            assets
        );

        (, int256 sDaiOut) = _swap(int256(assets), true);
        uint256 sDaiToTransfer = uint256(-sDaiOut);
        bool successSecond = IERC20(sDAI).transfer(msg.sender, sDaiToTransfer);

        if (!successFirst || !successSecond) {
            revert TransferFailed(msg.sender, address(this), assets);
        }

        return (true, sDaiToTransfer);
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        bool successFirst = IERC20(sDAI).transferFrom(
            msg.sender,
            address(this),
            shares
        );

        (int256 assets, ) = _swap(int256(shares), false);
        uint256 assetsToTransfer = uint256(-assets);
        bool successSecond = IERC20(asset).transfer(
            msg.sender,
            assetsToTransfer
        );

        if (!successFirst || !successSecond) {
            revert TransferFailed(msg.sender, address(this), assetsToTransfer);
        }

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

    function _swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal virtual returns (int256);
}