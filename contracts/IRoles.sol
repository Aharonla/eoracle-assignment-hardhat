// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IRoles {
    /**
     * @dev emitted when a role is added to `allowedRoles`
     */
    event RoleAdded(bytes32 indexed role);

    /**
     * @dev emitted when a role is removed from `allowedRoles`
     */
    event RoleRemoved(bytes32 indexed role);

    /**
     * @dev caller is not `admin`
     */
    error NotAdmin(address from);

    /**
     * @dev `role` is not listed in `allowedRoles`
     */
    error RoleNotAllowed(bytes32 role);

    /**
     * @dev `role` is already listed in `allowedRoles`
     */
    error RoleAllowed(bytes32 role);

    /**
     * @dev `grantRole` is overriden and reverts
     */
    error NoPublicGrantRole();

    /**
     * @dev Add role to allowedRoles mapping
     * Requirements:
     * - can only be accessed by `admin` role
     * - if `_role` is allowed, should revert with `RoleAllowed`
     * - should emit `RoleAdded` event
     * @param _role role to be added
     */
    function addRole(bytes32 _role) external;

    /**
     * @dev Remove role from allowedRoles mapping
     * Requirements:
     * - can only be accessed by `admin` role
     * - if `_role` is not allowed, should revert with `RoleNotAllowed`
     * - should emit `RoleRemoved` event
     * @param _role role to be removed
     */
    function removeRole(bytes32 _role) external;
}
