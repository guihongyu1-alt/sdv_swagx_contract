// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RoleManaged} from "./RoleManaged.sol";
import {ECDSA} from "../libraries/ECDSA.sol";

abstract contract SignatureRoleManaged is RoleManaged {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    error InvalidSignature();

    constructor(address admin, uint256 initialRescueTxLimit) RoleManaged(admin, initialRescueTxLimit) {}

    function _requireValidSignature(bytes32 structHash, bytes memory signature) internal view returns (address signer) {
        bytes32 digest = ECDSA.toEthSignedMessageHash(structHash);
        signer = ECDSA.recover(digest, signature);
        if (!hasRole(SIGNER_ROLE, signer)) {
            revert InvalidSignature();
        }
    }

    function _requireValidSignature(bytes32 structHash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address signer)
    {
        bytes32 digest = ECDSA.toEthSignedMessageHash(structHash);
        signer = ECDSA.recover(digest, v, r, s);
        if (!hasRole(SIGNER_ROLE, signer)) {
            revert InvalidSignature();
        }
    }
}
