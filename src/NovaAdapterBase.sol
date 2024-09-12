// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

abstract contract NovaAdapterBase is INovaAdapterBase {
    using SafeTransferLib for ERC20;

    address immutable savings;
    address immutable stable;

    constructor(address _stable, address _savings) {
        stable = _stable;
        savings = _savings;
    }

    function deposit(uint256 amountInStable) external returns (bool, uint256) {
        ERC20(stable).safeTransferFrom(
            msg.sender,
            address(this),
            amountInStable
        );

        (, int256 amountOutSavings) = _swap(int256(amountInStable), true);
        uint256 amountOutSavingsToTransfer = uint256(-amountOutSavings);
        ERC20(savings).safeTransfer(msg.sender, amountOutSavingsToTransfer);

        return (true, amountOutSavingsToTransfer);
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        ERC20(savings).safeTransferFrom(msg.sender, address(this), shares);

        (int256 amountOutStable, ) = _swap(int256(shares), false);
        uint256 amountOutStableToTransfer = uint256(-amountOutStable);
        ERC20(stable).safeTransfer(msg.sender, amountOutStableToTransfer);

        return (true, amountOutStableToTransfer);
    }

    /**
     * @notice Performs a swap operation between the stable and savings.
     * @dev This function interacts with the pool to execute the swap.
     * @param amount The amount to be swapped.
     * @param fromStableToSavings A boolean indicating the direction of the swap.
     *                         - `true` for swapping from the stable to savings.
     *                         - `false` for swapping from savings to the stable.
     * @return amount0 The amount of token0 involved in the swap.
     * @return amount1 The amount of token1 involved in the swap.
     */
    function _swap(
        int256 amount,
        bool fromStableToSavings
    ) internal virtual returns (int256, int256);
}
