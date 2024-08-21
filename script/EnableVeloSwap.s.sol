// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NovaVaultV2} from "../src/NovaVaultV2.sol";
import {IVelodromePool} from "../src/interfaces/IVelodromePool.sol";

contract EnableVeloSwap is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY_OWNER");

        vm.startBroadcast(privateKey);

        NovaVaultV2 vaultV2 = NovaVaultV2(0x04b12a2590BD808F7aC01f066aae0e2f48A3991C);
        IVelodromePool veloPool = IVelodromePool(0x131525f3FA23d65DC2B1EB8B6483a28c43B06916);

        //////////////////
        // NovaVaultV2 Setup
        //////////////////

        vaultV2.addDex(address(veloPool));
        vaultV2.setFunctionApprovalBySignature(veloPool.swap.selector);

        console.log("NovaVaultV2 added DEX ", address(veloPool));

        vm.stopBroadcast();
    }
}
