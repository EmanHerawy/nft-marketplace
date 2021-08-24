// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './StartFiMarketPlaceController.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Admin
 * [ desc ] : contract to handle the main functions for any marketplace
 */
abstract contract StartFiMarketPlaceAdmin is Ownable, Pausable, StartFiMarketPlaceController {
    /******************************************* decalrations go here ********************************************************* */

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        address ownerAddress,
        string memory _marketPlaceName,
        address _paymentContract,
        address _reputationContract
    ) StartFiMarketPlaceController(_marketPlaceName, _paymentContract, _reputationContract) {
        transferOwnership(ownerAddress);
    }

    /******************************************* read state functions go here ********************************************************* */

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
     *  @dev only called by `owner` or `priceFeeds` to update the STFI/usdt price
     * @param _usdCap  the new fees value to be stored
     * @param _stfiCap  the new basefees value to be stored
     */
    function setCap(uint256 _usdCap, uint256 _stfiCap) external onlyOwner {
        _setCap(_usdCap, _stfiCap);
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
}
