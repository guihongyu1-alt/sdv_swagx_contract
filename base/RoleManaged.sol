// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "../access/AccessControl.sol";
import {Pausable} from "../security/Pausable.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {SafeERC20} from "../libraries/SafeERC20.sol";

abstract contract RoleManaged is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant RELATION_ROLE = keccak256("RELATION_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");

    uint256 public rescueTxLimit;

    mapping(address => bool) private _blacklist;

    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event RescueTxLimitUpdated(uint256 previousLimit, uint256 newLimit);
    event EmergencyTokenRescued(address indexed token, address indexed to, uint256 amount, address indexed operator);

    error ZeroAddress();
    error InvalidAmount();
    error BlacklistedAccount(address account);
    error RescueLimitExceeded(uint256 requestedAmount, uint256 maxAmount);

    modifier onlyAdmin() {
        _checkRole(OPERATOR_ROLE, msg.sender);
        _;
    }

    modifier notBlacklisted(address account) {
        if (_blacklist[account]) {
            revert BlacklistedAccount(account);
        }
        _;
    }

    constructor(address admin, uint256 initialRescueTxLimit) {
        if (admin == address(0)) {
            revert ZeroAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);

        rescueTxLimit = initialRescueTxLimit;
        emit RescueTxLimitUpdated(0, initialRescueTxLimit);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _blacklist[account];
    }

    function _isBlacklisted(address account) internal view returns (bool) {
        return _blacklist[account];
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setBlacklist(address account, bool blocked) external onlyAdmin {
        if (account == address(0)) {
            revert ZeroAddress();
        }
        _blacklist[account] = blocked;
        emit BlacklistUpdated(account, blocked);
    }

    function setRescueTxLimit(uint256 newLimit) external onlyAdmin {
        uint256 previousLimit = rescueTxLimit;
        rescueTxLimit = newLimit;
        emit RescueTxLimitUpdated(previousLimit, newLimit);
    }

    function rescueToken(address token, address to, uint256 amount) external onlyRole(RESCUER_ROLE) {
        if (token == address(0) || to == address(0)) {
            revert ZeroAddress();
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (amount > rescueTxLimit) {
            revert RescueLimitExceeded(amount, rescueTxLimit);
        }

        IERC20(token).safeTransfer(to, amount);
        emit EmergencyTokenRescued(token, to, amount, msg.sender);
    }
}
