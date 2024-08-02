// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniPool} from "./interfaces/IUniPool.sol";

contract NovaVaultV2 {
    address immutable sDAI;
    address immutable swapFacet;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);
    error GenericSwapFailed();
    error InvalidAssetId();

    constructor(address _sDAI, address _swapFacet) {
        sDAI = _sDAI;
        swapFacet = _swapFacet;
    }

    modifier onlySDai(LibSwap.SwapData[] memory _swapData, bool isDeposit) {
        address assetId;
        if (isDeposit) {
            assetId = _swapData[_swapData.length - 1].receivingAssetId;
        } else {
            assetId = _swapData[0].sendingAssetId;
        }
        if (sDAI != assetId) {
            revert InvalidAssetId();
        }
        _;
    }

    function addDex(address _contract) external {
        LibAllowList.addAllowedContract(_contract);
    }

    function setFunctionApprovalBySignature(bytes4 _selector) external {
        LibAllowList.addAllowedSelector(_selector);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        IUniPool uniPool = IUniPool(msg.sender);
        address token0 = uniPool.token0();
        address token1 = uniPool.token1();

        if (amount0Delta > 0) {
            IERC20(token0).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(token1).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _swapTokensGeneric(
        address payable receiver,
        uint256 minAmount,
        LibSwap.SwapData[] memory swapData
    ) internal {
        (bool success, ) = swapFacet.delegatecall(
            abi.encodeWithSignature(
                "swapTokensGeneric(bytes32,string,string,address,uint256,(address,address,address,address,uint256,bytes,bool)[])",
                "",
                "integrator",
                "referrer",
                receiver,
                minAmount,
                swapData
            )
        );
        if (!success) {
            revert GenericSwapFailed();
        }
    }

    function deposit(
        LibSwap.SwapData[] memory swapData,
        uint16 referral
    ) external payable onlySDai(swapData, true) returns (bool, uint256) {
        uint256 prevBalance = IERC20(sDAI).balanceOf(address(this));

        _swapTokensGeneric(payable(address(this)), 1, swapData);

        uint256 sDaiAmount = IERC20(sDAI).balanceOf(address(this)) -
            prevBalance;
        IERC20(sDAI).transfer(msg.sender, sDaiAmount);
        emit Referral(referral, msg.sender, sDaiAmount);

        return (true, sDaiAmount);
    }

    function withdraw(
        uint16 referral,
        LibSwap.SwapData[] memory swapData
    ) external onlySDai(swapData, false) returns (bool, uint256) {
        address receivedAsset = swapData[0].receivingAssetId;

        uint256 prevBalance = IERC20(receivedAsset).balanceOf(address(this));

        _swapTokensGeneric(payable(address(this)), 1, swapData);

        uint256 assetAmount = IERC20(receivedAsset).balanceOf(address(this)) -
            prevBalance;
        IERC20(receivedAsset).transfer(msg.sender, assetAmount);
        emit Referral(referral, address(this), assetAmount);

        return (true, assetAmount);
    }

    function sequentialSwap(
        LibSwap.SwapData[] memory swapData,
        bytes memory callData,
        uint16 referral
    ) public onlySDai(swapData, true) returns (bool, uint256) {
        require(
            swapData[0].receivingAssetId == swapData[1].sendingAssetId,
            "invalid asset"
        );

        address asset = swapData[0].receivingAssetId;

        LibSwap.SwapData[] memory swapSequentially = new LibSwap.SwapData[](1);
        swapSequentially[0] = swapData[0];

        uint256 prevBalance = IERC20(asset).balanceOf(address(this));
        _swapTokensGeneric(payable(address(this)), 1, swapSequentially);
        uint256 receivedAmount = IERC20(asset).balanceOf(address(this)) -
            prevBalance;

        (
            bytes4 selector,
            address recipient,
            bool zeroForOne,
            int256 amountSpecified,
            uint160 sqrtPriceLimitX96,
            bytes memory swapCallData
        ) = abi.decode(
                callData,
                (bytes4, address, bool, int256, uint160, bytes)
            );

        amountSpecified = -1 * int256(receivedAmount);
        callData = abi.encodeWithSelector(
            selector,
            recipient,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            swapCallData
        );
        swapData[1].callData = callData;

        swapSequentially[0] = swapData[1];

        prevBalance = IERC20(sDAI).balanceOf(address(this));
        _swapTokensGeneric(payable(address(this)), 1, swapSequentially);
        uint256 sDaiAmount = IERC20(sDAI).balanceOf(address(this)) -
            prevBalance;

        IERC20(sDAI).transfer(msg.sender, sDaiAmount);
        emit Referral(referral, msg.sender, sDaiAmount);

        return (true, sDaiAmount);
    }
}
