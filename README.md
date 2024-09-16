# Nova vault

## introduction

This repository contains smart contract code of Nova vault.
Its goal is to allow stablecoin holders to receive DSR yield.
Its implementation is generic to support several stablecoins as inputs,
and several AMM to swap sDAI vs stablecoin.

Currently, we support:
- USDC as stablecoin
- Velodrome as AMM
- Optimism as chain

## development

run the following command to install git hooks to your local repo:
```bash
./setup.sh
```

## tests
```bash
export OPTIMISM_ALCHEMY_KEY=
forge test --fork-url optimism -vvv
```

## contracts

- [NovaAdapterVeloCLPool](https://optimistic.etherscan.io/address/0xD4Cd6B3e3fcd6399D534F7a07c18ed804B64e13e)
- [NovaVault](https://optimistic.etherscan.io/address/0xbf3ccf927eD469229ed834FD67004533f37a7291)
- [NovaVaultV2](https://optimistic.etherscan.io/address/0x04b12a2590BD808F7aC01f066aae0e2f48A3991C)
