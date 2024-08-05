// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LibSwap} from "@lifi/src/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniPool} from "./interfaces/IUniPool.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

contract NovaVaultV2 is ReentrancyGuard {
    address immutable sDAI;
    address immutable swapFacet;
    address private owner;

    error GenericSwapFailed();
    error InvalidAssetId(address assetId);
    error NotTheOwner();
    error InvalidAddress();
    error DexContractNotAllowed(address);
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

    constructor(address _sDAI, address _swapFacet, address _owner) {
        sDAI = _sDAI;
        swapFacet = _swapFacet;
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotTheOwner();
        }
        _;
    }

    modifier onlySDai(LibSwap.SwapData[] memory _swapData, bool isDeposit) {
        address assetId;
        if (isDeposit) {
            assetId = _swapData[_swapData.length - 1].receivingAssetId;
        } else {
            assetId = _swapData[0].sendingAssetId;
        }
        if (sDAI != assetId) {
            revert InvalidAssetId(assetId);
        }
        _;
    }

    modifier onlyAllowedDexContracts() {
        if (!LibAllowList.contractIsAllowed(msg.sender)) {
            revert DexContractNotAllowed(msg.sender);
        }
        _;
    }

    function addDex(address _contract) external onlyOwner {
        LibAllowList.addAllowedContract(_contract);
    }

    function setFunctionApprovalBySignature(
        bytes4 _selector
    ) external onlyOwner {
        LibAllowList.addAllowedSelector(_selector);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external onlyAllowedDexContracts {
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

    function deposit(
        LibSwap.SwapData[] memory swapData,
        uint16 referral
    )
        external
        payable
        nonReentrant
        onlySDai(swapData, true)
        returns (bool, uint256)
    {
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
    ) external nonReentrant onlySDai(swapData, false) returns (bool, uint256) {
        address receivedAsset = swapData[0].receivingAssetId;

        uint256 prevBalance = IERC20(receivedAsset).balanceOf(address(this));

        _swapTokensGeneric(payable(address(this)), 1, swapData);

        uint256 assetAmount = IERC20(receivedAsset).balanceOf(address(this)) -
            prevBalance;
        IERC20(receivedAsset).transfer(msg.sender, assetAmount);
        emit Referral(referral, address(this), assetAmount);

        return (true, assetAmount);
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

    function transferOwnership(address _newOwner) external onlyOwner {
        if (
            _newOwner == address(0) ||
            _newOwner == address(this) ||
            _newOwner == owner
        ) {
            revert InvalidAddress();
        }
        owner = _newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
