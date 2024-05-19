// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {console} from "forge-std/Test.sol";

abstract contract NovaAdapterBase is ERC20 {

    error TransferFailed(
        address sender,
        address recipient,
        uint256 amount
    );

    error SharesAmountExceeded(
        address sender,
        uint256 shares,
        uint256 sDAIperUser
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

    function deposit(uint256 assets) external returns (bool , uint256) {
        bool success = asset.transferFrom(msg.sender, address(this), assets);
        if(!success){
            revert TransferFailed(msg.sender, address(this), assets);
        }

        (, int256 sDai) = _swap(int256(assets), true);
        int256 sDaiToMint = -sDai;
        _mint(msg.sender, uint256(sDaiToMint));

        return (true, uint256(sDaiToMint));
    }

    function withdraw(uint256 shares) external returns (bool, uint256) {
        (int256 assets, ) = _swap(int256(shares), false);
        assets = -assets;

        _burn(msg.sender, uint256(shares));
        ERC20(address(asset)).transfer(msg.sender, uint256(assets));

        return (true, uint256(assets));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external virtual;

    function _swap(
        int256 amount,
        bool fromStableTosDai
    ) internal virtual returns (int256, int256);
}