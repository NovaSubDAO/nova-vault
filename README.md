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

- [NovaAdapterVelo](https://optimistic.etherscan.io/address/0xA0E5013486E9fecC15835B9D9c76bB209eA48273)
- [NovaVault](https://optimistic.etherscan.io/address/0x7A8F265F2d1362ED8b6D5dd52E82741217BE8D3C)