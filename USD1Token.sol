// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedSupplyToken} from "./token/FixedSupplyToken.sol";

contract USD1Token is FixedSupplyToken {
    uint256 private constant INITIAL_SUPPLY = 2_100_000_000 * 10 ** 18;

    constructor(
        address initialHolder
    )
        FixedSupplyToken(
            "World Liberty Financial USD",
            "USD1",
            18,
            INITIAL_SUPPLY,
            initialHolder
        )
    {}
}
