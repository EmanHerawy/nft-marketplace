// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;
import "./interface/IStartFiReputation.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IStartFiStakes.sol";
import "./MarketPlaceBase.sol";

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to handle all financial work for the marketplace
 * @title Startfi Marketplace Finance
 */
contract StartfiMarketPlaceFinance is MarketPlaceBase {
 /******************************************* decalrations go here ********************************************************* */
    address internal _paymentToken;
    uint256 internal _feeFraction = 1;
    uint256 internal _feeBase = 100;
    uint256 bidPenaltyPercentage =1;
    uint256 public delistFeesPercentage=1;
    uint256 public listqualifyPercentage=1;
    uint256 public bidPenaltyPercentageBase =100;
    uint256 public delistFeesPercentageBase=100;
    uint256 public listqualifyPercentageBase=100;
   mapping (address=>uint256) userReserves;
   mapping (address=>bytes32[]) userListing;
   address public stakeContract;
   address reputationContract;

 /******************************************* constructor goes here ********************************************************* */

  constructor(
        string memory _name ,
        address _paymentContract,
        address _reputationContract
    )   MarketPlaceBase(_name){
         
       
        _paymentToken = _paymentContract;
        reputationContract = _reputationContract;

      
    }


  /******************************************* modifiers go here ********************************************************* */



  /******************************************* read state functions go here ********************************************************* */
    
    function _calcSum(uint256 a, uint256 b) pure internal returns (uint256 result) {
        result= a + b;        
    }
    /**
     @dev calculat the platform fees
    *@param price  : item  price
    *@return fees the value that the platform will get
     */
    function _calcFees(uint256 price) view internal returns (uint256 fees) {

        fees= (price*_feeFraction)/_feeBase;    
    }
    /**
     @dev calculat the platform fine amount when seller delist before time
    *@param listingPrice  : item listing price
    *@return amount the value that the platform will get
     */
    function _getListingQualAmount(uint256 listingPrice) view internal returns (uint256 amount) {
        amount= (listingPrice*listqualifyPercentage)/ listqualifyPercentageBase;    
    }
/**
     @dev calculat the platform fine amount when seller delist before time
    *@param listingPrice  : item listing price
    *@return fineAmount the value that the platform will get
    *@return remaining the value remaing after subtracting the fine
     */
    function _getDeListingQualAmount(uint256 listingPrice) view internal returns (uint256 fineAmount , uint256 remaining) {
        fineAmount= (listingPrice * delistFeesPercentage) / delistFeesPercentageBase;    
        remaining =  _getListingQualAmount( listingPrice) - fineAmount;
    }
      /**
      @dev calculat the platform share when seller call disput
    *@param qualifyAmount  : seller defind value to be staked in order to participate in a gevin auction
    * @return fineAmount the value that the platform will get
    * @return remaining the value that the auction woner will get
     */
      function _calcBidDisputeFees(uint256 qualifyAmount) view internal returns (uint256 fineAmount , uint256 remaining) {   
        fineAmount= (qualifyAmount * bidPenaltyPercentage)/ bidPenaltyPercentageBase;    
        remaining = qualifyAmount - fineAmount;
    }
   function _getListingFinancialInfo(address _NFTContract,uint256 tokenId, uint256 bidPrice)  view internal returns   (address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice) {
             fees = _calcFees(bidPrice);
      netPrice = bidPrice - fees;
          // royalty check
          if(_supportRoyalty(_NFTContract)){
               ( issuer, royaltyAmount) =_getRoyaltyInfo( _NFTContract,  tokenId, bidPrice);
               if(royaltyAmount>0 && issuer!=address(0)){
                   netPrice= netPrice - royaltyAmount;
               }
          }
      
   }
    /**
    *@param user  : participant address
    * @return the value of user reserves
     */
    function getUserReserved(address user) external  view returns (uint256)  {
        return userReserves[user];
    }
     /**
    *
    * @return the value of the state variable `_feeFraction`
     */
         function getServiceFee() external view returns (uint256) {
        return _feeFraction;
    }
     /**
     * @dev :wrap function to get the total allowed number of tokens that this contract can transfer from the given account 

    * @param owner: owner address
    * @return allowed number of tokens that this contract can transfer from the owner account
     */
    function _getAllowance(address owner) view internal returns (uint256 ) {
        return IERC20(_paymentToken).allowance( owner, address(this));
    }
      /**
        * @dev this function calls StartFiStakes contract to get the total staked tokens for 'user' an substract the current reserves to get the total number of free tokens
        * @param staker : participant address
        * @return allowed number of tokens that this contract can transfer from the owner account
      */
    function _getStakeAllowance(address staker /*,uint256 prevAmount*/) view internal returns (uint256 ) {
        // user can bid multi time, we want to make sure we don't calc the old bid as sperated bid 
        uint256 userActualReserved= userReserves[staker];//.sub(prevAmount);
        return IStartFiStakes(stakeContract).getReserves( staker) - userActualReserved;
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
  function _deduct(address finePayer, address to, uint256 amount)  internal returns (bool ) {
          return IStartFiStakes(stakeContract).deduct(finePayer, to, amount);
    }
        /**
        * @notice  all conditions and checks are made prior to this function. math of point calcualtion is not done yet
        * @dev this function calls StartFiReputation contract to mint reputation points for both seller and buyer
        * @param seller : seller address
        * @param buyer : buyer address
        * @param amount : price
        * @return buyerBalance : buyer current reputation balance
        * @return sellerBalance : seller current reputation balance
      */
  function _addreputationPoints(address seller, address buyer, uint256 amount)  internal returns (uint256 buyerBalance, uint256 sellerBalance ) {
         // calc how much pint for both of them ??
         // TODO: math and logic for calc the point based on the amount
         uint256 sellerPoints=amount/2;
         uint256 buyerPoints=amount/ 2;
          sellerBalance= IStartFiReputation(reputationContract).mintReputation(seller,sellerPoints );
          buyerBalance= IStartFiReputation(reputationContract).mintReputation(buyer,buyerPoints );
    }
    function _safeTokenTransfer(address to, uint256 amount) internal returns (bool) {
        return IERC20(_paymentToken). transfer( to,  amount);
    }
        /**
        * @dev  Safely transfers `amount` of token from `from` to `to`.
        * @param from address representing the previous owner of the token
        * @param to target address that will receive the tokens
        * @param amount number of tokens to be transferred
        * See {transferFrom}
     */
    function _safeTokenTransferFrom(address from,address to, uint256 amount) internal returns (bool) {
        return IERC20(_paymentToken). transferFrom(from, to,  amount);
    }
     /**
        * @notice  all conditions and checks are made prior to this function
        * @dev called to set user reserves
        * @param user : participant address
        * @param newReservedValue : value to be sored as user reserve
      */
    function _setUserReserves(address user, uint256 newReservedValue) internal returns (bool) {
        userReserves[user]=newReservedValue;
        return true;
    }
          /**
        * @notice  all conditions and checks are made prior to this function
        * @dev called to increase or decrease user reserves
        * @param user : participant address
        * @param newReserves : value to be added or substracted
        * @param isAddition : true if we are adding the new value 
     */
    function _updateUserReserves(address user, uint256 newReserves, bool isAddition) internal returns (uint256 _userReserves) {
        _userReserves=  isAddition? userReserves[user] + newReserves : userReserves[user] - newReserves;
        userReserves[user]=_userReserves;
        return _userReserves;
    }

    /**
    *   * @notice  all conditions and checks are made prior to this function
        * @dev  the formula is (fees * 1000)/base 
        * @param newFees  the new fees value to be stored 
        * @param newBase  the new basefees value to be stored 
        * @return percentage the value of the state variable `_feeFraction`
     */
     function changeFees(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
        require(newFees <= newBase, "Fee fraction exceeded base.");
          percentage = (newFees * 1000) / newBase;
        require(percentage <= 30 && percentage >= 10, "Percentage should be from 1-3 %");

        _feeFraction = newFees;
        _feeBase = newBase;
     }
     
      /**
        * @notice  all conditions and checks are made prior to this function
        * @dev for later on upgrade , if we have
        * @param _token : startfi new utility contract
     */
function _changeUtiltiyToken(address _token) internal {
      _paymentToken=_token;  
     }
      /**
        * @notice  all conditions and checks are made prior to this function
        * @dev for later on upgrade , if we have
        * @param _reputationContract : startfi new reputation contract
     */
function _changeReputationContract(address _reputationContract) internal {
      reputationContract=_reputationContract;  
     }
/**
    * @notice  all conditions and checks are made prior to this function
    * @dev  the formula is (fees * 1000)/base 
    * @param newFees  the new fees value to be stored 
    * @param newBase  the new basefees value to be stored 
    * @return percentage the value of the state variable `_feeFraction`
*/
function _changeBidPenaltyPercentage(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
            require(newFees <= newBase, "Fee fraction exceeded base.");
            percentage = (newFees * 1000)  /  newBase;
            require(percentage <= 40 && percentage >= 10, "Percentage should be from 1-4 %");

            bidPenaltyPercentage =newFees;
            bidPenaltyPercentageBase =newBase;
        }
/**
    * @notice  all conditions and checks are made prior to this function
    * @dev  the formula is (fees * 1000)/base 
    * @param newFees  the new fees value to be stored 
    * @param newBase  the new basefees value to be stored 
    * @return percentage the value of the state variable `_feeFraction`
    */

function _changeDelistFeesPerentage(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
            require(newFees <= newBase, "Fee fraction exceeded base.");
            percentage = (newFees *  1000) / newBase;
            require(percentage <= 40 && percentage>= 10, "Percentage should be from 1-4 %");

            delistFeesPercentage =newFees;
            delistFeesPercentageBase =newBase;
        }
  /**
        * @notice  all conditions and checks are made prior to this function
        * @dev  the formula is (fees * 1000)/base 
        * @param newFees  the new fees value to be stored 
        * @param newBase  the new basefees value to be stored 
        * @return percentage the value of the state variable `_feeFraction`
     */
function _changeListqualifyAmount(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
            require(newFees <= newBase, "Fee fraction exceeded base.");
            percentage = (newFees * 1000) / newBase;
            require(percentage <= 40 && percentage >= 10, "Percentage should be from 1-4 %");

            listqualifyPercentage =newFees;
            listqualifyPercentageBase =newBase;
        }

} 