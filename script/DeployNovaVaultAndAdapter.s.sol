// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {NovaVault} from "../src/NovaVault.sol";
import {NovaAdapterVeloCLPool} from "../src/adapters/NovaAdapterVeloCLPool.sol";
import {IVelodromeCLPool} from "../src/interfaces/IVelodromeCLPool.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY_OWNER");

        vm.startBroadcast(privateKey);

        address POOL = 0x131525f3FA23d65DC2B1EB8B6483a28c43B06916;
        address sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
        NovaAdapterVeloCLPool adapter;
        NovaVault vault;
        IVelodromeCLPool veloPool;
        address stable;
        address veloToken0;
        address veloToken1;
        address[] memory stables = new address[](1);
        address[] memory novaAdapters = new address[](1);

        veloPool = IVelodromeCLPool(POOL);
        veloToken0 = veloPool.token0();
        veloToken1 = veloPool.token1();
        if (veloToken0 == sDAI) {
            stable = veloToken1;
        } else if (veloToken1 == sDAI) {
            stable = veloToken0;
        } else {
            revert("Velodrome pool should be made of `asset` and `savings`!");
        }

        //////////////////
        // NovaAdapterVeloCLPool Deployment
        //////////////////

        adapter = new NovaAdapterVeloCLPool(stable, sDAI, POOL);
        console.log("NovaAdapterVeloCLPool address is ", address(adapter));

        //////////////////
        // NovaVault Deployment
        //////////////////

        stables[0] = stable;
        novaAdapters[0] = address(adapter);

        vault = new NovaVault(sDAI, stables, novaAdapters);
        console.log("NovaVault address is ", address(vault));

        vm.stopBroadcast();
    }
}
