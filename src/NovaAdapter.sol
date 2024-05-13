// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {IVelodromePool} from "src/interfaces/IVelodromePool.sol";
import {console} from "forge-std/Test.sol";

contract NovaAdapter is ERC20 {

    error NovaAdapter__TransferFailed(
        address sender,
        address recipient,
        uint256 amount
    );

    error NovaAdapter__SharesAmountExceeded(
        address sender,
        uint256 shares,
        uint256 sDAIperUser
    );

    bool private isStableFirst;
    address immutable veloToken0;
    address immutable veloToken1;
    address immutable sDAI;
    uint256 private sDAIbalance = 0;
    uint256 private assetsBalance = 0;

    IVelodromePool public veloPool;
    ERC20 asset;

    mapping(address user => uint256 sDAI) private sDAIperUser;

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

    function deposit(uint256 assets) external {
        bool success = asset.transferFrom(msg.sender, address(this), assets);
        if(!success){
            revert NovaAdapter__TransferFailed(msg.sender, address(this), assets);
        }

        _swap(int256(assets), true);
        
        uint256 sDAInewBalance = ERC20(sDAI).balanceOf(address(this));
        uint256 sDAItoMint = sDAInewBalance - sDAIbalance;

        _mint(msg.sender, sDAItoMint);
        sDAIperUser[msg.sender] = sDAItoMint;

        sDAIbalance = sDAInewBalance;
    }

    function withdraw(uint256 shares) external {
        if (shares > sDAIperUser[msg.sender]) {
            revert NovaAdapter__SharesAmountExceeded(msg.sender, shares, sDAIperUser[msg.sender]);
        }

        assetsBalance = ERC20(address(asset)).balanceOf(address(this));

        _swap(int256(shares), false);
        _burn(msg.sender, shares);
        
        uint256 newAssetsBalance = ERC20(address(asset)).balanceOf(address(this));
        ERC20(address(asset)).transfer(msg.sender, newAssetsBalance - assetsBalance);

        sDAIbalance -= shares;
        sDAIperUser[msg.sender] -= shares;
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
    ) internal {
        (uint160 sqrtPriceX96, , , , , ) = veloPool.slot0();
        uint160 num = isStableFirst ? 95 : 105;
        int8 sign = fromStableTosDai ? int8(1) : int8(1);
        veloPool.swap(
            address(this),
            isStableFirst,
            sign * amount,
            (num * sqrtPriceX96) / 100,
            ""
        );
    }

    function getSdaiPerUser(address user) external view returns (uint256) {
        return sDAIperUser[user];
    }

    function convertTo18Decimals(
        uint256 amount
    ) internal pure returns (uint256) {
        return amount * 10 ** 12;
    }

    function getVeloToken0() external view returns (address) {
        return veloToken0;
    }

    function getVeloToken1() external view returns (address) {
        return veloToken1;
    }
}
