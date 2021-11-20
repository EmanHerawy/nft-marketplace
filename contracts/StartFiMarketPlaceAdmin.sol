// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 *@title  MarketPlace Admin
 * [ desc ] : contract to handle the main functions for any marketplace
 */
abstract contract StartFiMarketPlaceAdmin is AccessControlEnumerable, Pausable {
    /******************************************* decalrations go here ********************************************************* */
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
    bytes32 public constant PRICE_FEEDER_ROLE = keccak256('PRICE_FEEDER_ROLE');
    address _adminWallet;
    uint256 public fulfillDuration;

    uint256 public unpauseTimestamp;
    /******************************************* events goes here ********************************************************* */
    event ChangeReputationContract(address reputationContract);
    event ChangeUtilityToken(address utiltiyToken);
    event ChangeFulfillDuration(uint256 duration);
    event ChangeListInsuranceAmount(uint256 newFees, uint256 newBase);
    event ChangeMarketPlaceName(string Name);
    event ChangeFees(uint256 newFees, uint256 newBase);
    event UpdateAdminWallet(address newWallet);
    /******************************************* read state functions go here ********************************************************* */
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), 'caller is not the owner');

        _;
    }

    modifier notZeroAddress(address newAddress) {
        require(newAddress != address(0), 'Zero address is not allowed');

        _;
    }

    /******************************************* constructor goes here ********************************************************* */

    function _MarketplaceAdmin_init_unchained(address ownerAddress) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);

        _setupRole(OWNER_ROLE, ownerAddress);
        // we are assigned it to the owner for now until the chainlink price feed contract gets finished. once finished we will remove owner from this role

        _setupRole(PRICE_FEEDER_ROLE, ownerAddress);
        // we are assigned it to the owner for now until the contract gets finished. once finished we will remove owner from this role
        _adminWallet = ownerAddress;
    }

    /******************************************* state functions go here ********************************************************* */

    /**
     * @dev Pauses contract.
     *
     *
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses contract.
     *
     *
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function unpause() external virtual onlyOwner whenPaused {
        unpauseTimestamp = block.timestamp;
        _unpause();
    }

    /**
     * @dev update the admin wallet address.
     *
     *
     *
     * Requirements:
     *
     * - the caller must be the admin.
     * - the `newWallet` must not be empty.
     */
    function updateAdminWallet(address newWallet) external notZeroAddress(newWallet) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'UnAuthorized');
        _adminWallet = newWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, newWallet);
        emit UpdateAdminWallet(newWallet);
    }

    function changeFulfillDuration(uint256 _duration) external onlyOwner whenPaused {
        require(_duration > 1 days);
        fulfillDuration = _duration;
        emit ChangeFulfillDuration(_duration);
    }
}
