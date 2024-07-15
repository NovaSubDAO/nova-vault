// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GenericSwapFacet} from "@lifi/src/Facets/GenericSwapFacet.sol";
import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract NovaVaultV2 is GenericSwapFacet {
    mapping(address => address) public _novaAdapters;
    address immutable sDAI;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

    constructor(address _sDAI) {
        sDAI = _sDAI;
    }

    function deposit(
        bytes32 transactionId,
        string memory integrator,
        string memory referrer,
        address payable receiver,
        uint256 assetsAmount,
        LibSwap.SwapData[] memory swapDataDeposit,
        uint16 referral,
        address stable
    ) external returns (bool) {
        IERC20(stable).transferFrom(msg.sender, address(this), assetsAmount);
        IERC20(stable).approve(address(this), assetsAmount);
        this.swapTokensGeneric(
            transactionId,
            integrator,
            referrer,
            payable(address(this)),
            assetsAmount,
            swapDataDeposit
        );

        emit Referral(referral, receiver, assetsAmount);

        return (true);
    }

    function withdraw(
        bytes32 transactionId,
        string memory integrator,
        string memory referrer,
        address payable receiver,
        uint256 sDaiAmount,
        uint16 referral,
        LibSwap.SwapData[] memory swapDataWithdraw
    ) external returns (bool) {
        this.swapTokensGeneric(
            transactionId,
            integrator,
            referrer,
            receiver,
            sDaiAmount,
            swapDataWithdraw
        );

        emit Referral(referral, receiver, sDaiAmount);

        return (true);
    }
}
