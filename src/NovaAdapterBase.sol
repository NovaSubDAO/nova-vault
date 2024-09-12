// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

abstract contract NovaAdapterBase is INovaAdapterBase {
    using SafeTransferLib for ERC20;

    address immutable sDAI;
    address immutable asset;

    constructor(address _asset, address _sDAI) {
        asset = _asset;
        sDAI = _sDAI;
    }

    function deposit(uint256 assets) external returns (bool, uint256) {
        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        (, int256 sDaiOut) = _swap(int256(assets), true);
        uint256 sDaiToTransfer = uint256(-sDaiOut);
        ERC20(sDAI).safeTransfer(msg.sender, sDaiToTransfer);

        return (true, sDaiToTransfer);
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        ERC20(sDAI).safeTransferFrom(msg.sender, address(this), shares);

        (int256 assets, ) = _swap(int256(shares), false);
        uint256 assetsToTransfer = uint256(-assets);
        ERC20(asset).safeTransfer(msg.sender, assetsToTransfer);

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
