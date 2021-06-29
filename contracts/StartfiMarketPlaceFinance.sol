// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IStartFiStakes.sol";
import "./MarketPlaceBase.sol";

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to handel all financial work for the marketplace
 * @title Startfi Marketplace Finance
 */
contract StartfiMarketPlaceFinance is MarketPlaceBase {
 /******************************************* decalrations go here ********************************************************* */
    using SafeMath for uint256;
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
 /******************************************* constructor goes here ********************************************************* */

  constructor(
                 string memory _name ,
        address _paymentTokesnAddress
    )   MarketPlaceBase(_name){
         
       
        _paymentToken = _paymentTokesnAddress;
    }


  /******************************************* modifiers go here ********************************************************* */



  /******************************************* read state functions go here ********************************************************* */
    
    function _calcSum(uint256 a, uint256 b) pure internal returns (uint256 result) {
        result= a.add(b);        
    }
    function _calcFees(uint256 bidPrice) view internal returns (uint256 fees) {

        fees= bidPrice.mul(_feeFraction).div(_feeBase );    
    }
    function _getListingQualAmount(uint256 listingPrice) view internal returns (uint256 amount) {
        amount= listingPrice.mul(listqualifyPercentage).div( listqualifyPercentageBase);    
    }
    function _getDeListingQualAmount(uint256 listingPrice) view internal returns (uint256 fineAmount , uint256 remaining) {
        fineAmount= listingPrice.mul(delistFeesPercentage).div( delistFeesPercentageBase);    
        remaining =  _getListingQualAmount( listingPrice).sub(fineAmount);
    }
      function _calcBidDisputeFees(uint256 qualifyAmount) view internal returns (uint256 fineAmount , uint256 remaining) {   
        fineAmount= qualifyAmount.mul(bidPenaltyPercentage).div( bidPenaltyPercentageBase);    
        remaining = qualifyAmount.sub(fineAmount);
    }
   function _getListingFinancialInfo(address contractAddress,uint256 tokenId, uint256 bidPrice)  view internal returns   (address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice) {
             fees = _calcFees(bidPrice);
      netPrice = bidPrice.sub(fees);
          // royalty check
          if(_supportRoyalty(contractAddress)){
               ( issuer, royaltyAmount) =_getRoyaltyInfo( contractAddress,  tokenId, bidPrice);
               if(royaltyAmount>0 && issuer!=address(0)){
                   netPrice= netPrice.sub(royaltyAmount);
               }
          }
      
   }
    function getUserReserved(address user) external  view returns (uint256)  {
        return userReserves[user];
    }
    /// @return the value of the state variable `_feeFraction`
        function getServiceFee() external view returns (uint256) {
        return _feeFraction;
    }
    function _getAllowance(address owner) view internal returns (uint256 ) {
        return IERC20(_paymentToken).allowance( owner, address(this));
    }
    function _getStakeAllowance(address user ,uint256 prevAmount) view internal returns (uint256 ) {
        // user can bid multi time, we want to make sure we don't calc the old bid as sperated bid 
        uint256 userActualReserved= userReserves[user].sub(prevAmount);
        return IStartFiStakes(stakeContract).getReserves( user).sub(userActualReserved);
    }
    function _deduct(address finePayer, address to, uint256 amount)  internal returns (bool ) {
          return IStartFiStakes(stakeContract).deduct(finePayer, to, amount);
    }

      /******************************************* state functions go here ********************************************************* */

    function _safeTokenTransfer(address to, uint256 amount) internal returns (bool) {
        return IERC20(_paymentToken). transfer( to,  amount);
    }
    function _safeTokenTransferFrom(address from,address to, uint256 amount) internal returns (bool) {
        return IERC20(_paymentToken). transferFrom(from, to,  amount);
    }
    function _setUserReserves(address user, uint256 newReservedValue) internal returns (bool) {
        userReserves[user]=newReservedValue;
        return true;
    }
    function _updateUserReserves(address user, uint256 newReserves, bool isAddition) internal returns (uint256 _userReserves) {
        _userReserves=  isAddition? userReserves[user].add(newReserves): userReserves[user].sub(newReserves);
        userReserves[user]=_userReserves;
        return _userReserves;
    }

    /**
    *
    * @dev  the formula is (fees * 1000)/base 
    * @param newFees  the new fees value to be stored 
    * @param newBase  the new basefees value to be stored 
    * @return percentage the value of the state variable `_feeFraction`
     */
     function changeFees(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
        require(newFees <= newBase, "Fee fraction exceeded base.");
          percentage = (newFees. mul( 1000)) .div( newBase);
        require(percentage <= 30 && percentage < 10, "Percentage should be from 1-3 %");

        _feeFraction = newFees;
        _feeBase = newBase;
     }
     
    /// @param _token  the new name to be stored 
     function _changeUtiltiyToken(address _token) internal {
      _paymentToken=_token;  
     }
     function _changeBidPenaltyPercentage(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
        require(newFees <= newBase, "Fee fraction exceeded base.");
          percentage = (newFees. mul( 1000)) .div( newBase);
        require(percentage <= 40 && percentage < 10, "Percentage should be from 1-4 %");

        bidPenaltyPercentage =newFees;
        bidPenaltyPercentageBase =newBase;
}
function _changeDelistFeesPerentage(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
        require(newFees <= newBase, "Fee fraction exceeded base.");
          percentage = (newFees. mul( 1000)) .div( newBase);
        require(percentage <= 40 && percentage < 10, "Percentage should be from 1-4 %");

        delistFeesPercentage =newFees;
        delistFeesPercentageBase =newBase;
 }
function _changeListqualifyAmount(uint256 newFees, uint256 newBase) internal returns (uint256 percentage) {
        require(newFees <= newBase, "Fee fraction exceeded base.");
          percentage = (newFees. mul( 1000)) .div( newBase);
        require(percentage <= 40 && percentage < 10, "Percentage should be from 1-4 %");

        listqualifyPercentage =newFees;
        listqualifyPercentageBase =newBase;
}

} 