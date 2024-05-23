// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Errors} from "./libraries/Errors.sol";
import {INovaVault} from "./interfaces/INovaVault.sol";
import {INovaAdapterBase} from "./interfaces/INovaAdapterBase.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {console} from "forge-std/console.sol";

contract NovaVault is INovaVault {
    mapping(address => address) public _novaAdapters;

    constructor(
        address[] memory stables,
        address[] memory novaAdapters
    ) {
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

    function _approveAdapter(
        address stable,
        address adapter
    ) internal  {
        require(stable != address(0), Errors.INVALID_ADDRESS);

        require(
            _novaAdapters[stable] == address(0),
            Errors.ADAPTER_ALREADY_APPROVED
        );

        ERC20 underlyingAsset = INovaAdapterBase(adapter).getAsset();
        
        require(
            address(underlyingAsset) == stable,
            Errors.INVALID_STABLE_TO_ADAPTER_MAPPING
        );

        _novaAdapters[stable] = adapter;
        emit ApprovedAdapter(stable, adapter);
    }

    function deposit(address stable, uint256 assets) external returns (bool , bytes memory) {
        address adapter = _novaAdapters[stable];
        require(
            adapter != address(0),
            Errors.NO_ADAPTER_APPROVED
        );
        
        ERC20(stable).transferFrom(msg.sender, adapter, assets);

        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("deposit(uint256)", assets)
        );
        return (success, data);
    }

    function withdraw(address stable, uint256 shares) external returns (bool , bytes memory) {
        address adapter = _novaAdapters[stable];
        require(
            adapter != address(0),
            Errors.NO_ADAPTER_APPROVED
        );
        (bool success, bytes memory data) = adapter.call(
            abi.encodeWithSignature("withdraw(uint256)", shares)
        );
        return (success, data);
    }
}