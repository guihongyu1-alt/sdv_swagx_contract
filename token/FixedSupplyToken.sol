// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "./ERC20.sol";

contract FixedSupplyToken is ERC20 {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply,
        address initialHolder
    ) ERC20(tokenName, tokenSymbol, tokenDecimals) {
        _mint(initialHolder, initialSupply);
    }
}
