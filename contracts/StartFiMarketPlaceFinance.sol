// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
pragma abicoder v2;
import './interface/IStartFiReputation.sol';

import './interface/IStartFiStakes.sol';
import './library/StartFiFinanceLib.sol';

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to handle all financial work for the marketplace
 * @title StartFi Marketplace Finance
 */
contract StartFiMarketPlaceFinance {
    /******************************************* decalrations go here ********************************************************* */
    address internal reputationContract;
    address internal _paymentToken;
    uint256 internal _feeFraction = 25; // 2.5% fees
    uint256 internal _feeBase = 10; // 25/10=2.5
    mapping(address => uint256) internal userReserves;
    address public stakeContract;
    uint256 public listqualifyPercentage = 10;
    uint256 public listqualifyPercentageBase = 10;

    /******************************************* constructor goes here ********************************************************* */

    constructor(address _paymentContract, address _reputationContract) {
        _paymentToken = _paymentContract;
        reputationContract = _reputationContract;
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
     * @dev this function calls StartFiStakes contract to get the total staked tokens for 'user' an substract the current reserves to get the total number of free tokens
     * @param staker : participant address
     * @return allowed number of tokens that this contract can transfer from the owner account
     */
    function getStakeAllowance(
        address staker /*,uint256 prevAmount*/
    ) public view returns (uint256) {
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
     * @notice  all conditions and checks are made prior to this function. math of point calcualtion is not done yet
     * @dev this function calls StartFiReputation contract to mint reputation points for both seller and buyer
     * @param seller : seller address
     * @param buyer : buyer address
     * @param amount : price
     */
    function _addreputationPoints(
        address seller,
        address buyer,
        uint256 amount
    ) internal returns (bool) {
        // calc how much pint for both of them ??
        // logic and math is defind in the contract
        return IStartFiReputation(reputationContract).calcAndMintintReputation(buyer, seller, amount);
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev called to set user reserves
     * @param user : participant address
     * @param newReservedValue : value to be sored as user reserve
     */
    function _setUserReserves(address user, uint256 newReservedValue) internal returns (bool) {
        userReserves[user] = newReservedValue;
        return true;
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev called to increase or decrease user reserves
     * @param user : participant address
     * @param newReserves : value to be added or substracted
     * @param isAddition : true if we are adding the new value
     */
    function _updateUserReserves(
        address user,
        uint256 newReserves,
        bool isAddition
    ) internal returns (uint256 _userReserves) {
        _userReserves = isAddition ? userReserves[user] + newReserves : userReserves[user] - newReserves;
        userReserves[user] = _userReserves;
        return _userReserves;
    }

    /**
     *   * @notice  all conditions and checks are made prior to this function
     * @dev  the formula is (fees * 1000)/base
     * @param numerator  the new fees value to be stored
     * @param donomirator  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     */
    function _changeFees(uint256 numerator, uint256 donomirator) internal returns (uint256 percentage) {
        percentage = StartFiFinanceLib._calcShare(numerator, donomirator);
        require(percentage <= 4 ether && percentage >= 1 ether, 'Percentage should be from 1-4 %');

        _feeFraction = numerator;
        _feeBase = donomirator;
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev for later on upgrade , if we have
     * @param _token : startfi new utility contract
     */
    function _changeUtilityToken(address _token) internal {
        _paymentToken = _token;
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev for later on upgrade , if we have
     * @param _reputationContract : startfi new reputation contract
     */
    function _changeReputationContract(address _reputationContract) internal {
        reputationContract = _reputationContract;
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev  the formula is (fees * 1000)/base
     * @param numerator  the new fees value to be stored
     * @param donomirator  the new basefees value to be stored
     * @return percentage the value of the state variable `_feeFraction`
     */
    function _changeListInsuranceAmount(uint256 numerator, uint256 donomirator) internal returns (uint256 percentage) {
        percentage = StartFiFinanceLib._calcShare(numerator, donomirator);
        require(percentage <= 4 ether && percentage >= 1 ether, 'Percentage should be from 1-4 %');

        listqualifyPercentage = numerator;
        listqualifyPercentageBase = donomirator;
    }
}
