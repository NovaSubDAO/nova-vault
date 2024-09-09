// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface INovaVault {
    event AdapterApproval(address stable, address indexed adapter);
    event Referral(uint16 referral, address indexed depositor, uint256 amount);
}
