// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {INovaVault} from "./interfaces/INovaVault.sol";
import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {Errors} from "./libraries/Errors.sol";

contract NovaVault is INovaVault, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    mapping(address => address) public _novaAdapters;
    address immutable sDAI;

    modifier onlyNonZero(address asset) {
        if (asset == address(0)) {
            revert Errors.INVALID_ADDRESS();
        }
        _;
    }

    modifier onlyApprovedAdapter(address stable) {
        if (_novaAdapters[stable] == address(0)) {
            revert Errors.NO_ADAPTER_APPROVED();
        }
        _;
    }
    constructor(
        address _sDAI,
        address[] memory stables,
        address[] memory novaAdapters
    ) onlyNonZero(_sDAI) {
        sDAI = _sDAI;
        _approveNovaAdapters(stables, novaAdapters);
    }

    function _approveNovaAdapters(
        address[] memory stables,
        address[] memory novaAdapters
    ) internal {
        if (stables.length != novaAdapters.length) {
            revert Errors.MISMATCHING_ARRAYS_LENGTH();
        }

        for (uint256 i = 0; i < stables.length; i++) {
            _approveAdapter(stables[i], novaAdapters[i]);
        }
    }

    function _approveAdapter(
        address stable,
        address adapter
    ) internal onlyNonZero(stable) {
        if (_novaAdapters[stable] == adapter) {
            revert Errors.ADAPTER_ALREADY_APPROVED();
        }

        address underlyingAsset = INovaAdapterBase(adapter).getAsset();
        if (underlyingAsset != stable) {
            revert Errors.INVALID_STABLE_TO_ADAPTER_MAPPING();
        }

        _novaAdapters[stable] = adapter;
        emit AdapterApproval(stable, adapter);
    }

    function replaceAdapter(address stable, address adapter) external {
        _approveAdapter(stable, adapter);
    }

    function deposit(
        address stable,
        uint256 assets,
        uint16 referral
    )
        external
        onlyApprovedAdapter(stable)
        nonReentrant
        returns (bool, uint256)
    {
        address adapter = _novaAdapters[stable];

        ERC20(stable).safeTransferFrom(msg.sender, address(this), assets);
        ERC20(stable).safeApprove(adapter, assets);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("deposit(uint256)", assets)
        );
        (bool successDeposit, uint256 sDaiAmount) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successDeposit, "Deposit failed");

        ERC20(sDAI).safeTransfer(msg.sender, sDaiAmount);

        emit Referral(referral, msg.sender, assets);
        return (true, sDaiAmount);
    }

    function withdraw(
        address stable,
        uint256 shares,
        uint16 referral
    )
        external
        onlyApprovedAdapter(stable)
        nonReentrant
        returns (bool, uint256)
    {
        address adapter = _novaAdapters[stable];

        ERC20(sDAI).safeTransferFrom(msg.sender, address(this), shares);
        ERC20(sDAI).safeApprove(adapter, shares);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("withdraw(uint256)", shares)
        );
        (bool successWithdraw, uint256 assetsAmount) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successWithdraw, "Withdraw failed");

        ERC20(stable).safeTransfer(msg.sender, assetsAmount);

        emit Referral(referral, msg.sender, shares);
        return (true, assetsAmount);
    }
}
