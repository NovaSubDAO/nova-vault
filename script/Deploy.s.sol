// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import {NovaVaultV2} from "../src/NovaVaultV2.sol";
import {GenericSwapFacetV3} from "@lifi/src/Facets/GenericSwapFacetV3.sol";

// Deploy a contract to a deterministic address with create2 factory.
contract Deploy is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY_OWNER");

        vm.startBroadcast(privateKey);

        address sDAI = 0x2218a117083f5B482B0bB821d27056Ba9c04b1D3;
        NovaVaultV2 vaultV2;
        GenericSwapFacetV3 swapFacet;

        //////////////////
        // NovaVaultV2 Deployment
        //////////////////

        swapFacet = new GenericSwapFacetV3();

        vaultV2 = new NovaVaultV2(sDAI, address(swapFacet));
        console.log("NovaVaultV2 address is ", address(vaultV2));

        vm.stopBroadcast();
    }
}
