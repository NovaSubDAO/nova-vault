// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract NovaVaultV2 {
    address immutable sDAI;
    address immutable swapFacet;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

    constructor(address _sDAI, address _swapFacet) {
        sDAI = _sDAI;
        swapFacet = _swapFacet;
    }

    function addDex(address _dex) external {
        LibAllowList.addAllowedContract(_dex);
    }

    function setFunctionApprovalBySignature(bytes4 _signature) external {
        LibAllowList.addAllowedSelector(_signature);
    }

    function uniswapV3SwapCallback(int256, int256, bytes calldata) external {}

    function _swapTokensGeneric(
        bytes32 transactionId,
        string memory integrator,
        string memory referrer,
        address payable receiver,
        uint256 minAmount,
        LibSwap.SwapData[] memory swapData
    ) internal {
        (bool success, bytes memory data) = swapFacet.delegatecall(
            abi.encodeWithSignature(
                "swapTokensGeneric(bytes32, string calldata, string calldata, address payable, uint256, LibSwap.SwapData[] calldata)",
                transactionId,
                integrator,
                referrer,
                receiver,
                minAmount,
                swapData
            )
        );
        (bool successDeposit, ) = abi.decode(data, (bool, uint256));
        require(success && successDeposit, "Deposit failed");
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
    ) external payable returns (bool, uint256) {
        IERC20(stable).transferFrom(msg.sender, address(this), assetsAmount);
        IERC20(stable).approve(address(this), assetsAmount);

        uint256 prevBalance = IERC20(sDAI).balanceOf(msg.sender);

        _swapTokensGeneric(
            transactionId,
            integrator,
            referrer,
            receiver,
            assetsAmount,
            swapDataDeposit
        );

        uint256 sDaiAmount = IERC20(sDAI).balanceOf(msg.sender) - prevBalance;
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
        _swapTokensGeneric(
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
