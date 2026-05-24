// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./interfaces/IERC20.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {ReentrancyGuard} from "./security/ReentrancyGuard.sol";
import {SignatureRoleManaged} from "./base/SignatureRoleManaged.sol";

contract SdvBurn is SignatureRoleManaged, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = address(0);
    struct SignedBurnRecord {
        uint256 orderId;
        uint256 timestamp;
        address user;
        uint256 amount;
        address signer;
    }

    struct SignerBurnRecord {
        uint256 orderId;
        uint256 timestamp;
        address user;
        uint256 amount;
        address operator;
    }

    address public sdvToken;

    mapping(uint256 => SignedBurnRecord) public signedBurnOrders;
    mapping(uint256 => SignerBurnRecord) public signerBurnOrders;

    event SdvTokenUpdated(address indexed previousToken, address indexed newToken);
    event SignedBurnExecuted(uint256 indexed orderId, address indexed user, uint256 amount, address indexed signer);
    event SignerBurnExecuted(uint256 indexed orderId, address indexed user, uint256 amount, address indexed operator);

    error SdvTokenNotConfigured();
    error OrderAlreadyUsed(uint256 orderId);
    error InvalidDeadline(uint256 deadline);

    constructor(address admin, uint256 initialRescueTxLimit) SignatureRoleManaged(admin, initialRescueTxLimit) {}

    function setSdvToken(address newSdvToken) external onlyAdmin {
        if (newSdvToken == address(0)) {
            revert ZeroAddress();
        }

        address previousToken = sdvToken;
        sdvToken = newSdvToken;
        emit SdvTokenUpdated(previousToken, newSdvToken);
    }

    function burnWithSignature(uint256 amount, uint256 orderId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
        whenNotPaused
        notBlacklisted(msg.sender)
    {
        if (block.timestamp > deadline) {
            revert InvalidDeadline(deadline);
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (signedBurnOrders[orderId].timestamp != 0) {
            revert OrderAlreadyUsed(orderId);
        }

        address token = sdvToken;
        if (token == address(0)) {
            revert SdvTokenNotConfigured();
        }

        bytes32 structHash = keccak256(abi.encode(address(this), msg.sender, orderId, amount, deadline));
        address signer = _requireValidSignature(structHash, v, r, s);

        IERC20(token).safeTransferFrom(msg.sender, BURN_ADDRESS, amount);

        signedBurnOrders[orderId] =
            SignedBurnRecord({orderId: orderId, timestamp: block.timestamp, user: msg.sender, amount: amount, signer: signer});

        emit SignedBurnExecuted(orderId, msg.sender, amount, signer);
    }

    function burnBySigner(address user, uint256 amount, uint256 orderId)
        external
        onlyRole(SIGNER_ROLE)
        nonReentrant
        whenNotPaused
        notBlacklisted(user)
    {
        if (user == address(0)) {
            revert ZeroAddress();
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (signerBurnOrders[orderId].timestamp != 0) {
            revert OrderAlreadyUsed(orderId);
        }

        address token = sdvToken;
        if (token == address(0)) {
            revert SdvTokenNotConfigured();
        }

        IERC20(token).safeTransferFrom(user, BURN_ADDRESS, amount);

        signerBurnOrders[orderId] = SignerBurnRecord({
            orderId: orderId,
            timestamp: block.timestamp,
            user: user,
            amount: amount,
            operator: msg.sender
        });

        emit SignerBurnExecuted(orderId, user, amount, msg.sender);
    }
}
