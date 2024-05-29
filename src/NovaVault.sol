// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Errors} from "./libraries/Errors.sol";
import {INovaVault} from "./interfaces/INovaVault.sol";
import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract NovaVault is INovaVault {
    mapping(address => address) public _novaAdapters;
    address immutable sDAI;
    event Referral(uint16 referral, address indexed depositor, uint256 amount);

    constructor(
        address _sDAI,
        address[] memory stables,
        address[] memory novaAdapters
    ) {
        sDAI = _sDAI;
        _approveNovaAdapters(stables, novaAdapters);
    }

    function _approveNovaAdapters(
        address[] memory stables,
        address[] memory novaAdapters
    ) internal {
        require(
            stables.length == novaAdapters.length,
            Errors.MISMATCHING_ARRAYS_LENGTH
        );
        for (uint256 i = 0; i < stables.length; i++) {
            _approveAdapter(stables[i], novaAdapters[i]);
        }
    }

    function _approveAdapter(address stable, address adapter) internal {
        require(stable != address(0), Errors.INVALID_ADDRESS);

        require(
            _novaAdapters[stable] != adapter,
            Errors.ADAPTER_ALREADY_APPROVED
        );

        address underlyingAsset = INovaAdapterBase(adapter).getAsset();

        require(
            underlyingAsset == stable,
            Errors.INVALID_STABLE_TO_ADAPTER_MAPPING
        );

        _novaAdapters[stable] = adapter;
        emit AdapterApproval(stable, adapter);
    }

    function switchAdapter(address stable, address adapter) external {
        _approveAdapter(stable, adapter);
    }

    function deposit(
        address stable,
        uint256 assets,
        uint16 referral
    ) external returns (bool, uint256) {
        address adapter = _novaAdapters[stable];
        require(adapter != address(0), Errors.NO_ADAPTER_APPROVED);

        IERC20(stable).transferFrom(msg.sender, address(this), assets);
        IERC20(stable).approve(adapter, assets);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("deposit(uint256)", assets)
        );
        (bool successDeposit, uint256 sDaiAmount) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successDeposit, "Deposit failed");

        IERC20(sDAI).transfer(msg.sender, sDaiAmount);

        emit Referral(referral, msg.sender, assets);

        return (true, sDaiAmount);
    }

    function withdraw(
        address stable,
        uint256 shares
    ) external returns (bool, uint256) {
        address adapter = _novaAdapters[stable];
        require(adapter != address(0), Errors.NO_ADAPTER_APPROVED);

        IERC20(sDAI).transferFrom(msg.sender, address(this), shares);
        IERC20(sDAI).approve(adapter, shares);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("withdraw(uint256)", shares)
        );
        (bool successWithdraw, uint256 assetsAmount) = abi.decode(
            data,
            (bool, uint256)
        );

        require(success && successWithdraw, "Withdraw failed");

        IERC20(stable).transfer(msg.sender, assetsAmount);

        return (true, assetsAmount);
    }
}