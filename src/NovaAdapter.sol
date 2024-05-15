// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IVelodromePool} from "src/interfaces/IVelodromePool.sol";
import {console} from "forge-std/Test.sol";

contract NovaAdapter is ERC20 {

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

    bool private isStableFirst;
    address immutable veloToken0;
    address immutable veloToken1;
    address immutable sDAI;

    IVelodromePool public veloPool;
    ERC20 asset;

    constructor(
        ERC20 _asset,
        address _pool,
        address _sDAI,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        veloPool = IVelodromePool(_pool);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();
        asset = _asset;
        sDAI = _sDAI;

        if ((veloToken0 == address(asset)) && (veloToken1 == sDAI)) {
            isStableFirst = true;
        } else if ((veloToken0 == sDAI) && (veloToken1 == address(asset))) {
            isStableFirst = false;
        } else {
            revert("Velodrome pool should be made of `_asset` and `sDAI`!");
        }
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

    function withdraw(uint256 shares) external {
        (int256 assets, ) = _swap(int256(shares), false);
        _burn(msg.sender, uint256(assets));
        ERC20(address(asset)).transfer(msg.sender, uint256(assets));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(msg.sender == address(veloPool), "Caller is not VelodromePool");

        if (amount0Delta > 0){
            ERC20(veloToken0).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0){
            ERC20(veloToken1).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _swap(
        int256 amount,
        bool fromStableTosDai
    ) internal returns (int256, int256){
        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = isStableFirst ? 95 : 105;
        int256 sign = fromStableTosDai ? int256(1) : int256(-1);
        
        (int256 amount0, int256 amount1) = veloPool.swap(
            address(this),
            isStableFirst,
            sign * amount,
            (num * sqrtPriceX96) / 100,
            ""
        );

        return (amount0, amount1);
    }
}
