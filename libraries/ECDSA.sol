// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ECDSA {
    error InvalidSignatureLength();
    error InvalidSignatureS();
    error InvalidSignatureV();
    error InvalidRecoveredAddress();

    bytes32 private constant MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        if (signature.length != 65) {
            revert InvalidSignatureLength();
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (uint256(s) > uint256(MALLEABILITY_THRESHOLD)) {
            revert InvalidSignatureS();
        }
        if (v != 27 && v != 28) {
            revert InvalidSignatureV();
        }

        signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            revert InvalidRecoveredAddress();
        }
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address signer) {
        if (uint256(s) > uint256(MALLEABILITY_THRESHOLD)) {
            revert InvalidSignatureS();
        }
        if (v != 27 && v != 28) {
            revert InvalidSignatureV();
        }

        signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            revert InvalidRecoveredAddress();
        }
    }
}
