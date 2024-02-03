// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IRoles } from "./IRoles.sol";

contract Roles is IRoles, AccessControlUpgradeable {
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    mapping(bytes32 role => bool isAllowed) private roles;

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAdmin(_msgSender());
        }
        _;
    }

    modifier existingRole(bytes32 _role) {
        if (!roles[_role]) {
            revert RoleNotAllowed(_role);
        }
        _;
    }

    /**
     * @dev Overrides AccessControl's `grantRole` function to allow only internal use of _grantRole
     */
    function grantRole(bytes32, address) public pure override {
        revert NoPublicGrantRole();
    }

    /**
     * @dev Adds role to allowed roles
     * @param _role The role to add
     */
    function addRole(bytes32 _role) external onlyAdmin {
        if (roles[_role]) {
            revert RoleAllowed(_role);
        }
        roles[_role] = true;
        emit RoleAdded(_role);
    }

    /**
     * @dev Removes role from allowed roles
     * @param _role The role to remove
     */
    function removeRole(bytes32 _role) external onlyAdmin existingRole(_role) {
        roles[_role] = false;
        emit RoleRemoved(_role);
    }
}
