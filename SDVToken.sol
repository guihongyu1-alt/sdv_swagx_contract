// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedSupplyToken} from "./token/FixedSupplyToken.sol";

contract SDVToken is FixedSupplyToken {
    uint256 private constant INITIAL_SUPPLY = 2_100_000_000 * 10 ** 18;

    constructor(
        address initialHolder
    ) FixedSupplyToken("SDV", "SDV", 18, INITIAL_SUPPLY, initialHolder) {}
}
