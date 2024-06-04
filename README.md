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

- [NovaAdapterVelo](https://optimistic.etherscan.io/address/0x56ebcb8e3db5324e0ce697babe66805e060b3733)
- [NovaVault](https://optimistic.etherscan.io/address/0x36a2f7fb07c102415afe2461a9a43377970e081c)