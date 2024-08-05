// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NovaVault} from "../src/NovaVault.sol";
import {NovaVaultV2} from "../src/NovaVaultV2.sol";
import {NovaAdapterVelo} from "../src/NovaAdapterVelo.sol";
import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";
import {GenericSwapFacet} from "@lifi/src/Facets/GenericSwapFacet.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    function run() external {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);

        vm.startBroadcast(privateKey);

        address POOL = 0x131525f3FA23d65DC2B1EB8B6483a28c43B06916;
        address sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
        NovaAdapterVelo adapter;
        NovaVault vault;
        NovaVaultV2 vaultV2;
        GenericSwapFacet swapFacet;
        IVelodromePool veloPool;
        address underlyingAddress;
        address veloToken0;
        address veloToken1;
        address[] memory stables = new address[](1);
        address[] memory novaAdapters = new address[](1);

        veloPool = IVelodromePool(POOL);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();
        if (veloToken0 == sDAI) {
            underlyingAddress = veloToken1;
        } else if (veloToken1 == sDAI) {
            underlyingAddress = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `sDAI`!");
        }

        //////////////////
        // NovaAdapterVelo Deployment
        //////////////////

        adapter = new NovaAdapterVelo(underlyingAddress, sDAI, POOL);
        console.log("NovaAdapterVelo address is ", address(adapter));

        //////////////////
        // NovaVault Deployment
        //////////////////

        stables[0] = underlyingAddress;
        novaAdapters[0] = address(adapter);

        vault = new NovaVault(sDAI, stables, novaAdapters);
        console.log("NovaVault address is ", address(vault));

        //////////////////
        // NovaVaultV2 Deployment
        //////////////////

        swapFacet = new GenericSwapFacet();

        vaultV2 = new NovaVaultV2(sDAI, address(swapFacet), msg.sender);
        console.log("NovaVault address is ", address(vault));

        vm.stopBroadcast();
    }
}
