// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import './interface/IStartFiStakes.sol';
import './library/StartFiFinanceLib.sol';
import './MarketPlaceBase.sol';

/**
 *desc   contract to handle all financial work for the marketplace
 * @title StartFi Marketplace Finance
 */
contract StartFiMarketPlaceFinance is MarketPlaceBase {
    /******************************************* decalrations go here ********************************************************* */
    address internal _paymentToken;
    uint256 internal _feeFraction; // 2.5% fees
    uint256 internal _feeBase; // 25/10=2.5
    address public stakeContract;
    uint256 public listqualifyPercentage;
    uint256 public listqualifyPercentageBase;
    mapping(address => uint256) internal userReserves;

    event UserReservesRelease(address user, uint256 lastReserves, uint256 newReserves, uint256 timestamp);

    /******************************************* constructor goes here ********************************************************* */

    function _MarketplaceFinance_init_unchained(address _paymentContract) internal {
        _paymentToken = _paymentContract;
    }

    /******************************************* modifiers go here ********************************************************* */

    /******************************************* read state functions go here ********************************************************* */

    /**
     *
     * @return the value of the state variable `_feeFraction`
     */
    function getServiceFee() external view returns (uint256) {
        return _feeFraction;
    }

    /**
     * @dev called by the dapp to get the user stakes on hold
     *@param user  : participant address
     * @return the value of user reserves
     */
    function getUserReserved(address user) external view returns (uint256) {
        return userReserves[user];
    }

    /**
     * @dev this function calls StartFiStakes contract to get the total staked tokens for 'user' an substract the current reserves to get the total number of free tokens
     * @param staker : participant address
     * @return allowed number of tokens that this contract can transfer from the owner account
     */
    function getStakeAllowance(
        address staker /*,uint256 prevAmount*/
    ) external view returns (uint256) {
        return _getStakeAllowance(staker);
    }

    function _getStakeAllowance(
        address staker /*,uint256 prevAmount*/
    ) internal view returns (uint256) {
        // user can bid multi time, we want to make sure we don't calc the old bid as sperated bid
        uint256 userActualReserved = userReserves[staker]; //.sub(prevAmount);
        return IStartFiStakes(stakeContract).getReserves(staker) - userActualReserved;
    }

    /******************************************* state functions go here ********************************************************* */
    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev this function calls StartFiStakes contract to subtract the user stakes and add that value to the 'to'
     * @param finePayer : fine payer address
     * @param to : participant address
     * @param amount : value to be deducted from his stakes as a fine
     * @return true if it's done
     */
    function _deduct(
        address finePayer,
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IStartFiStakes(stakeContract).deduct(finePayer, to, amount);
    }

    /**
     *  @notice only called by `owner` to change the name and `whenPaused`
     * @dev  the formula is (fees * 1000)/base
     * @param numerator  the new fees value to be stored
     * @param donomirator  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     */
    function changeFees(uint256 numerator, uint256 donomirator)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = StartFiFinanceLib._calcShare(numerator, donomirator);
        require(percentage <= 4 ether && percentage >= 1 ether, 'Percentage should be from 1-4 %');

        _feeFraction = numerator;
        _feeBase = donomirator;
        emit ChangeFees(numerator, donomirator);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _token token address
     *
     */
    function changeUtilityToken(address _token) external notZeroAddress(_token) onlyOwner whenPaused {
        _paymentToken = _token;
        emit ChangeUtilityToken(_token);
    }

    /**
     * @notice only called by `owner` to change the name and `whenPaused`
     * @dev  the formula is (fees * 1000)/base
     * @param numerator  the new fees value to be stored
     * @param donomirator  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     *
     */
    function changeListInsuranceAmount(uint256 numerator, uint256 donomirator)
        external
        onlyOwner
        whenPaused
        returns (uint256 percentage)
    {
        percentage = StartFiFinanceLib._calcShare(numerator, donomirator);
        require(percentage <= 4 ether && percentage >= 1 ether, 'Percentage should be from 1-4 %');

        listqualifyPercentage = numerator;
        listqualifyPercentageBase = donomirator;
        emit ChangeListInsuranceAmount(numerator, donomirator);
    }
}
