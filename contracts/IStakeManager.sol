// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface IStakeManager {
    /**
     * @dev Emitted after setting protocol configurations
     */
    event SetConfiguration(uint256 indexed amount, uint256 indexed time);

    /**
     * @dev Emitted after registering as staker
     * @param stake The amount added by the registering staker
     */
    event Register(uint256 indexed stake);

    /**
     * @dev Emitted after staker unregistering from the protocol
     * @param stake The amount withrawn by the exiting staker
     */
    event Unregister(uint256 indexed stake);

    /**
     * @dev Emitted when staker adds funds to stake
     * @param stake The amount added
     */
    event Stake(uint256 indexed stake);

    /**
     * @dev Emitted when staker withdraws funds
     * @param stake The amount withdrawn
     */
    event Unstake(uint256 indexed stake);

    /**
     * @dev Emitted when staker is penalized
     * @param staker The penalized staker
     * @param amount Amount slashed from stake
     * @param cooldown End of cooldown period
     */
    event Slash(address indexed staker, uint256 indexed amount, uint256 indexed cooldown);

    /**
     * @dev Emitted when a staker claims a role
     * @param staker The staker claiming the role
     * @param role The role claimed (bytes32 representation)
     */
    event RoleClaimed(address staker, bytes32 role);

    /**
     * @dev Emitted when admin withdraws the slashed funds
     * @param amount The withdraw amount
     */
    event Withdraw(uint256 amount);

    /**
     * @dev Incorrect ether amount sent to register. Should be `registrationDepositAmount`
     */
    error IncorrectAmountSent();

    /**
     * @dev The calling staker is in cooldown period
     */
    error Restricted();

    /**
     * @dev Staked funds insufficient for the attempted action
     */
    error NotEnoughFunds(address staker, uint256 requiredFunds, uint256 availableFunds);

    /**
     * @dev caller is not `staker`
     */
    error NotStaker(address caller);

    /**
     * @dev User is already a staker
     */
    error StakerRoleClaimed(address staker, bytes32 role);

    /**
     * @dev Allows an admin to set the configuration of the staking contract.
     * @param registrationDepositAmount Initial registration deposit amount in wei.
     * @param registrationWaitTime The duration a staker must wait after initiating registration.
     */
    function setConfiguration(uint128 registrationDepositAmount, uint64 registrationWaitTime) external;

    /**
     * @dev Allows an account to register as a staker.
     */
    function register() external payable;

    /**
     * @dev used by stakers to claim roles
     * @param _role the role's "name" (Should be fixed length (bytes32),
     * and by convention is an upper-cased underscored string)
     * Restrictions:
     * - Can be accessed only by stakers
     * - `_role` should be permitted by manager
     * - Calling staker can not be in cooldown period
     * - Staker has not claimed `_role` before
     * - Staker has enough staked funds to claim another role
     */
    function claimRole(bytes32 _role) external;

    /**
     * @dev Allows a registered staker to unregister and exit the staking system.
     */
    function unregister() external payable;

    /**
     * @dev Allows registered stakers to stake ether into the contract.
     */
    function stake() external payable;

    /**
     * @dev Allows registered stakers to unstake their ether from the contract.
     */
    function unstake(uint128 _amount) external;

    /**
     * @dev Allows an admin to slash a portion of the staked ether of a given staker.
     * @param staker The address of the staker to be slashed.
     * @param amount The amount of ether to be slashed from the staker.
     */
    function slash(address staker, uint128 amount) external;

    /**
     * @dev used to withdraw all slashed funds from the contract
     * Restrictions:
     * - Callable only by admin
     */
    function withdraw() external;
}
