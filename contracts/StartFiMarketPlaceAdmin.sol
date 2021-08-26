// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import './StartFiMarketPlaceController.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Admin
 * [ desc ] : contract to handle the main functions for any marketplace
 */
abstract contract StartFiMarketPlaceAdmin is AccessControlEnumerable, Pausable, StartFiMarketPlaceController {
    /******************************************* decalrations go here ********************************************************* */
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
    bytes32 public constant PRICE_FEEDER_ROLE = keccak256('PRICE_FEEDER_ROLE');
    address _adminWallet;

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        address ownerAddress,
        string memory _marketPlaceName,
        address _paymentContract,
        address _reputationContract
    ) StartFiMarketPlaceController(_marketPlaceName, _paymentContract, _reputationContract) {
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);

        _setupRole(OWNER_ROLE, ownerAddress);
        _setupRole(PRICE_FEEDER_ROLE, ownerAddress);
        _adminWallet = ownerAddress;
    }

    /******************************************* read state functions go here ********************************************************* */
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), 'StartFiMarketPlaceAdmin: caller is not the owner');

        _;
    }

    /******************************************* state functions go here ********************************************************* */

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _reputationContract marketplace reputation contract
     *
     */
    function changeReputationContract(address _reputationContract) external onlyOwner whenPaused {
        _changeReputationContract(_reputationContract);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _token token address
     *
     */
    function changeUtiltiyToken(address _token) external onlyOwner whenPaused {
        _changeUtiltiyToken(_token);
    }

    /**
     * @dev only called by `owner` to change the fulfill Duration for auctions and `whenPaused`
     *@param duration duration for bid winner to fulfill an auction
     *
     */
    function changeFulfillDuration(uint256 duration) external onlyOwner whenPaused {
        require(duration > 1 days, 'Invalid duration');
        fulfillDuration = duration;
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     *
     */
    function changeListqualifyAmount(uint256 newFees, uint256 newBase)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = _changeListqualifyAmount(newFees, newBase);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     *
     */
    function changeDelistFeesPerentage(uint256 newFees, uint256 newBase)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = _changeDelistFeesPerentage(newFees, newBase);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param duration duration
     *
     */
    function changeDelistAfter(uint256 duration) external onlyOwner whenPaused {
        _changeDelistAfter(duration);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     *
     */
    function changeBidPenaltyPercentage(uint256 newFees, uint256 newBase)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = _changeBidPenaltyPercentage(newFees, newBase);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _name marketplace new name
     *
     */
    function changeMarketPlaceName(string memory _name) external onlyOwner whenPaused {
        _changeMarketPlaceName(_name);
    }

    /**
     *  @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     */
    function changeFees(uint256 newFees, uint256 newBase) external onlyOwner whenPaused returns (uint256 percentage) {
        percentage = _changeFees(newFees, newBase);
    }

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
    function updateAdminWallet(address newWallet) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'UnAuthorized caller');
        require(newWallet != address(0), 'Zero address is not allowed');
        _adminWallet = newWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, newWallet);
    }
}
