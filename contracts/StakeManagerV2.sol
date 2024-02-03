// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IStakeManager } from "./IStakeManager.sol";
import { Roles } from "./Roles.sol";

/// @custom:oz-upgrades-from contracts/StakeManager.sol:StakeManager
contract StakeManagerV2 is Initializable, IStakeManager, Roles, UUPSUpgradeable {
    /**
     * @dev Stores staker's info:
     * stake: All of the staker's staked funds
     * cooldown: For penalized stakers, a cooldown period until staker rights can be used
     * numRoles: Number of roles the staker has, to control permitted number of roles by `stake`
     */
    struct StakerInfo {
        uint8 numRoles;
        uint64 cooldown;
        uint128 stake;
    }
    /**
     * @dev Storage structure of the StakeManager contract
     */

    struct StakeManagerStorage {
        uint64 registrationWaitTime;
        uint128 registrationDepositAmount;
        uint128 slashedFunds;
        mapping(address staker => StakerInfo info) stakers;
        /**
         * @dev Stores the staker's roles by index (iMax = stakers[staker].numRoles)
         * to allow revoking roles iteratively once staker unregisters.
         */
        mapping(address staker => mapping(uint256 index => bytes32 role)) stakerRoles;
    }

    StakeManagerStorage private stakeManagerStorage;

    event FakeEvent();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Enforces `registrationDepositAmount` for new stakers registration.
     */
    modifier CheckRegistrationAmount() {
        if (msg.value != stakeManagerStorage.registrationDepositAmount) {
            revert IncorrectAmountSent();
        }
        _;
    }

    /**
     * @dev Enforces slashed staker restriction
     */
    modifier NotRestricted() {
        if (stakeManagerStorage.stakers[_msgSender()].cooldown > block.timestamp) {
            revert Restricted();
        }
        _;
    }

    /**
     * @dev Controls access to functions allowed only for staker role
     */
    modifier onlyStaker() {
        if (!hasRole(STAKER_ROLE, _msgSender())) {
            revert NotStaker(_msgSender());
        }
        _;
    }

    /**
     * @dev Used by admin to control state parameters
     * @param _registrationDepositAmount: Amount required to register as staker
     * @param _registrationWaitTime: Cooldown period for slashed stakers
     */
    function setConfiguration(uint128 _registrationDepositAmount, uint64 _registrationWaitTime) external onlyAdmin {
        emit FakeEvent();
        stakeManagerStorage.registrationDepositAmount = _registrationDepositAmount;
        stakeManagerStorage.registrationWaitTime = _registrationWaitTime;
        emit SetConfiguration(_registrationDepositAmount, _registrationWaitTime);
    }

    /**
     * @dev Registers a user as staker
     * @notice Restrictions:
     * - msg.value should equal `_registrationDepositAmount`
     */
    function register() external payable CheckRegistrationAmount {
        stakeManagerStorage.stakers[_msgSender()].stake += SafeCast.toUint128(msg.value);
        _grantRole(STAKER_ROLE, _msgSender());
        emit Register(stakeManagerStorage.stakers[_msgSender()].stake);
    }

    /**
     * @dev used by stakers to claim roles
     * @param _role the role's "name" (Should be fixed length (bytes32),
     * and by convention is an upper-cased underscored string)
     * @notice Restrictions:
     * - Can be accessed only by stakers
     * - `_role` should be permitted by manager
     * - Calling staker can not be in cooldown period
     * - Staker has not claimed `_role` before
     * - Staker has enough staked funds to claim another role
     */
    function claimRole(bytes32 _role) external onlyStaker existingRole(_role) NotRestricted {
        if (hasRole(_role, _msgSender())) {
            revert StakerRoleClaimed(_msgSender(), _role);
        }
        if (
            (stakeManagerStorage.stakers[_msgSender()].numRoles + 1) * stakeManagerStorage.registrationDepositAmount
                > stakeManagerStorage.stakers[_msgSender()].stake
        ) {
            revert NotEnoughFunds(
                _msgSender(),
                (stakeManagerStorage.stakers[_msgSender()].numRoles + 1) 
                * stakeManagerStorage.registrationDepositAmount,
                stakeManagerStorage.stakers[_msgSender()].stake
            );
        }
        stakeManagerStorage.stakerRoles[_msgSender()][stakeManagerStorage.stakers[_msgSender()].numRoles] = _role;
        stakeManagerStorage.stakers[_msgSender()].numRoles++;
        _grantRole(_role, _msgSender());
        emit RoleClaimed(_msgSender(), _role);
    }

    /**
     * @dev used to renounce all roles (including `staker`) and get staked funds refunded
     * @notice Restrictions:
     * - Callable only by stakers
     * - Calling staker can not be in cooldown period
     */
    function unregister() external payable onlyStaker NotRestricted {
        uint256 returnValue = stakeManagerStorage.stakers[_msgSender()].stake;
        for (uint256 i; i < stakeManagerStorage.stakers[_msgSender()].numRoles; i++) {
            renounceRole(stakeManagerStorage.stakerRoles[_msgSender()][i], _msgSender());
            delete(stakeManagerStorage.stakerRoles[_msgSender()][i]);
        }
        renounceRole(STAKER_ROLE, _msgSender());
        delete(stakeManagerStorage.stakers[_msgSender()]);
        emit Unregister(returnValue);
        payable(_msgSender()).transfer(returnValue);
    }

    /**
     * @dev used to add staked funds by staker
     * @notice Restrictions:
     * - Only stakers can call
     */
    function stake() external payable onlyStaker {
        stakeManagerStorage.stakers[_msgSender()].stake += SafeCast.toUint128(msg.value);
        emit Stake(msg.value);
    }

    /**
     * @dev used to withdraw staked funds by staker
     * @param _amount Amount of funds to withdraw
     * @notice Restrictions:
     * - Only stakers can call
     * - Staker should not be in cooldown period
     * - Staker can not withdraw if
     * - Staker has enough staked funds for existing roles after withdrawal.
     * If last restriction is not met, staker should call `renounceRole`
     * to reduce the number of roles until unstaking is possible
     */
    function unstake(uint128 _amount) external onlyStaker NotRestricted {
        if (
            stakeManagerStorage.stakers[_msgSender()].numRoles * stakeManagerStorage.registrationDepositAmount
                > (stakeManagerStorage.stakers[_msgSender()].stake - _amount)
        ) {
            revert NotEnoughFunds(
                _msgSender(),
                _amount,
                stakeManagerStorage.stakers[_msgSender()].numRoles * stakeManagerStorage.registrationDepositAmount
                    - stakeManagerStorage.stakers[_msgSender()].stake
            );
        }
        stakeManagerStorage.stakers[_msgSender()].stake -= _amount;
        emit Unstake(_amount);
        payable(_msgSender()).transfer(_amount);
    }

    /**
     * @dev Used to penalize a staker by slashing part or all of their staked funds
     * The penalty also involves a cooldown period, restricting staker's actions
     * @param staker The penalized staker
     * @param amount The amount of funds to slash
     * @notice Restrictions:
     * - Only admin can call
     * - `amount` is higher than or equal the staker's funds
     */
    function slash(address staker, uint128 amount) external onlyAdmin {
        if (stakeManagerStorage.stakers[staker].stake < amount) {
            revert NotEnoughFunds(staker, amount, stakeManagerStorage.stakers[staker].stake);
        }
        stakeManagerStorage.stakers[staker].stake -= amount;
        stakeManagerStorage.stakers[staker].cooldown =
            uint64(block.timestamp) + stakeManagerStorage.registrationWaitTime;
        stakeManagerStorage.slashedFunds += amount;
        emit Slash(staker, amount, stakeManagerStorage.stakers[staker].cooldown);
    }

    /**
     * @dev used to withdraw all slashed funds from the contract
     * @notice Restrictions:
     * - Callable only by admin
     */
    function withdraw() external onlyAdmin {
        uint256 returnValue = stakeManagerStorage.slashedFunds;
        stakeManagerStorage.slashedFunds = 0;
        emit Withdraw(returnValue);
        payable(_msgSender()).transfer(returnValue);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin { }
}
