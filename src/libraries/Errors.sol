// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Errors {
    string public constant INVALID_ADDRESS = "1";
    string public constant ADAPTER_ALREADY_APPROVED = "2";
    string public constant MISMATCHING_ARRAYS_LENGTH = "3";
    string public constant INVALID_STABLE_TO_ADAPTER_MAPPING = "4";
    string public constant NO_ADAPTER_APPROVED = "5";
}
