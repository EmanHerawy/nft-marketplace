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
    /******************************************* events goes here ********************************************************* */
    event ChangeReputationContract(address reputationContract);
    event ChangeUtilityToken(address utiltiyToken);
    event ChangeFulfillDuration(uint256 duration);
    event ChangeListInsuranceAmount(uint256 newFees, uint256 newBase);
    event ChangeDelistAfter(uint256 duration);
    event ChangeMarketPlaceName(string Name);
    event ChangeFees(uint256 newFees, uint256 newBase);
    event UpdateAdminWallet(address newWallet);

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
     *@param wallet marketplace reputation contract
     *@param _delistAfter marketplace reputation contract
     *@param _fee marketplace reputation contract
     *@param _listqualifyPercentage marketplace reputation contract
     *@param _listqualifyPercentage marketplace reputation contract
     *@param feeBase marketplace reputation contract
     *
     */
    function addOffer(
        address wallet,
        uint256 _delistAfter,
        uint256 _fee, // 2.5% fees
        uint256 _listqualifyPercentage,
        uint256 _listqualifyPercentageBase,
        uint256 feeBase
    ) external onlyOwner whenNotPaused {
        _addOffer(
            wallet,
            _delistAfter,
            _fee, // 2.5% fees
            _listqualifyPercentage,
            _listqualifyPercentageBase,
            feeBase
        );
        emit NewOffer(
            _msgSender(),
            wallet,
            _delistAfter,
            _fee,
            _listqualifyPercentage,
            _listqualifyPercentageBase,
            feeBase
        );
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _reputationContract marketplace reputation contract
     *
     */
    function changeReputationContract(address _reputationContract) external onlyOwner whenPaused {
        _changeReputationContract(_reputationContract);
        emit ChangeReputationContract(_reputationContract);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _token token address
     *
     */
    function changeUtilityToken(address _token) external onlyOwner whenPaused {
        _changeUtilityToken(_token);
        emit ChangeUtilityToken(_token);
    }

    /**
     * @dev only called by `owner` to change the fulfill Duration for auctions and `whenPaused`
     *@param duration duration for bid winner to fulfill an auction
     *
     */
    function changeFulfillDuration(uint256 duration) external onlyOwner whenPaused {
        require(duration > 1 days, 'Invalid duration');
        fulfillDuration = duration;
        emit ChangeFulfillDuration(duration);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     *
     */
    function changeListInsuranceAmount(uint256 newFees, uint256 newBase)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = _changeListInsuranceAmount(newFees, newBase);
        emit ChangeListInsuranceAmount(newFees, newBase);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param duration duration
     *
     */
    function changeDelistAfter(uint256 duration) external onlyOwner whenPaused {
        _changeDelistAfter(duration);
        emit ChangeDelistAfter(duration);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _name marketplace new name
     *
     */
    function changeMarketPlaceName(string memory _name) external onlyOwner whenPaused {
        _changeMarketPlaceName(_name);
        emit ChangeMarketPlaceName(_name);
    }

    /**
     *  @dev only called by `owner` to change the name and `whenPaused`
     * @param newFees  the new fees value to be stored
     * @param newBase  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     */
    function changeFees(uint256 newFees, uint256 newBase) external onlyOwner whenPaused returns (uint256 percentage) {
        percentage = _changeFees(newFees, newBase);
        emit ChangeFees(newFees, newBase);
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
        emit UpdateAdminWallet(newWallet);
    }
}