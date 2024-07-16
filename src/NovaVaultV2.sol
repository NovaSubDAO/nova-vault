// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GenericSwapFacet} from "@lifi/src/Facets/GenericSwapFacet.sol";
import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract NovaVaultV2 is GenericSwapFacet {
    mapping(address => address) public _novaAdapters;
    address immutable sDAI;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

    constructor(address _sDAI) {
        sDAI = _sDAI;
    }

    function addDex(address _dex) external {
        LibAllowList.addAllowedContract(_dex);
    }

    function setFunctionApprovalBySignature(bytes4 _signature) external {
        LibAllowList.addAllowedSelector(_signature);
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
    ) external returns (bool, uint256) {
        IERC20(stable).transferFrom(msg.sender, address(this), assetsAmount);
        IERC20(stable).approve(address(this), assetsAmount);

        (bool success, bytes memory data) = address(this).delegatecall(
            abi.encodeWithSignature(
                "swapTokensGeneric(bytes32, string calldata, string calldata, address payable, uint256, LibSwap.SwapData[] calldata)",
                transactionId,
                integrator,
                referrer,
                receiver,
                assetsAmount,
                swapDataDeposit
            )
        );
        (bool successDeposit, uint256 sDaiAmount) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successDeposit, "Deposit failed");

        IERC20(sDAI).transfer(msg.sender, sDaiAmount);

        emit Referral(referral, msg.sender, assetsAmount);

        return (true, sDaiAmount);
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
