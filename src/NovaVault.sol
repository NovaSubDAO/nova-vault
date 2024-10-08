// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {INovaVault} from "./interfaces/INovaVault.sol";
import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "./libraries/Errors.sol";

contract NovaVault is INovaVault, Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    mapping(address => address) public _novaAdapters;
    address immutable savings;

    modifier onlyNonZero(address stable) {
        if (stable == address(0)) {
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
        address _savings,
        address[] memory stables,
        address[] memory novaAdapters
    ) Ownable() onlyNonZero(_savings) {
        savings = _savings;
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

        address underlyingAsset = INovaAdapterBase(adapter).getStable();
        if (underlyingAsset != stable) {
            revert Errors.INVALID_STABLE_TO_ADAPTER_MAPPING();
        }

        _novaAdapters[stable] = adapter;
        emit AdapterApproval(stable, adapter);
    }

    function replaceAdapter(
        address stable,
        address adapter
    ) external onlyOwner {
        _approveAdapter(stable, adapter);
    }

    function deposit(
        address stable,
        uint256 amounInStable,
        uint16 referral
    )
        external
        onlyApprovedAdapter(stable)
        nonReentrant
        returns (bool, uint256)
    {
        address adapter = _novaAdapters[stable];

        ERC20(stable).safeTransferFrom(
            msg.sender,
            address(this),
            amounInStable
        );
        ERC20(stable).safeApprove(adapter, amounInStable);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("deposit(uint256)", amounInStable)
        );
        (bool successDeposit, uint256 savingsAmount) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successDeposit, "Deposit failed");

        ERC20(savings).safeTransfer(msg.sender, savingsAmount);

        emit Referral(referral, msg.sender, amounInStable);
        return (true, savingsAmount);
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

        ERC20(savings).safeTransferFrom(msg.sender, address(this), shares);
        ERC20(savings).safeApprove(adapter, shares);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("withdraw(uint256)", shares)
        );
        (bool successWithdraw, uint256 amountOutStable) = abi.decode(
            data,
            (bool, uint256)
        );
        require(success && successWithdraw, "Withdraw failed");

        ERC20(stable).safeTransfer(msg.sender, amountOutStable);

        emit Referral(referral, msg.sender, shares);
        return (true, amountOutStable);
    }
}
