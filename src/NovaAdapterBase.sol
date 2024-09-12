// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

abstract contract NovaAdapterBase is INovaAdapterBase {
    using SafeTransferLib for ERC20;

    address immutable savings;
    address immutable asset;

    constructor(address _asset, address _savings) {
        asset = _asset;
        savings = _savings;
    }

    function deposit(uint256 assets) external returns (bool, uint256) {
        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        (, int256 savingsOut) = _swap(int256(assets), true);
        uint256 savingsToTransfer = uint256(-savingsOut);
        ERC20(savings).safeTransfer(msg.sender, savingsToTransfer);

        return (true, savingsToTransfer);
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        ERC20(savings).safeTransferFrom(msg.sender, address(this), shares);

        (int256 assets, ) = _swap(int256(shares), false);
        uint256 assetsToTransfer = uint256(-assets);
        ERC20(asset).safeTransfer(msg.sender, assetsToTransfer);

        return (true, assetsToTransfer);
    }

    /**
     * @notice Performs a swap operation between the stable asset and savings.
     * @dev This function interacts with the pool to execute the swap.
     * @param amount The amount to be swapped.
     * @param fromStableToSavings A boolean indicating the direction of the swap.
     *                         - `true` for swapping from the stable asset to savings.
     *                         - `false` for swapping from savings to the stable asset.
     * @return amount0 The amount of token0 involved in the swap.
     * @return amount1 The amount of token1 involved in the swap.
     */
    function _swap(
        int256 amount,
        bool fromStableToSavings
    ) internal virtual returns (int256, int256);
}
