// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import './StartFiRoyalityLib.sol';
import './WadRayMath.sol';

library StartFiFinanceLib {
    using WadRayMath for uint256;

    function _calcSum(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = a + b;
    }

    /**
     @dev calculat the platform fees
    *@param price  : item  price
    *@return fees the value that the platform will get
     */
    function _calcFees(
        uint256 price,
        uint256 _fee,
        uint256 _feeBase
    ) internal pure returns (uint256 fees) {
        fees = price.wadMul(_fee).wadDiv(_feeBase);
    }

    /**
     @dev calculat the platform fine amount when seller delist before time
    *@param listingPrice  : item listing price
    *@param delistFeesPercentage delist Fees .  the formula is (delist fees * 1000)/ delist base
    *@param delistFeesPercentageBase delist fee base 
    *@param listqualifyPercentage listqualify fee .  the formula is (listqualify fees * 1000)/ listqualify base
     *@param listqualifyPercentageBase listqualify fee base 
    *@return fineAmount the value that the platform will get
    *@return remaining the value remaing after subtracting the fine
     */
    function _getDeListingQualAmount(
        uint256 listingPrice,
        uint256 delistFeesPercentage,
        uint256 delistFeesPercentageBase,
        uint256 listqualifyPercentage,
        uint256 listqualifyPercentageBase
    ) internal pure returns (uint256 fineAmount, uint256 remaining) {
        fineAmount = (listingPrice * delistFeesPercentage) / delistFeesPercentageBase;
        remaining = _calcFees(listingPrice, listqualifyPercentage, listqualifyPercentageBase) - fineAmount;
    }

    /**
      @dev calculat the platform share when seller call disput
    *@param qualifyAmount  : seller defind value to be staked in order to participate in a gevin auction
    *@param bidPenaltyPercentage bid Penalty fees.  the formula is ( bid Penalty * 1000)/  bid Penalty base
     *@param bidPenaltyPercentageBase  bid Penalty fee base 
    * @return fineAmount the value that the platform will get
    * @return remaining the value that the auction woner will get
     */
    function _calcBidDisputeFees(
        uint256 qualifyAmount,
        uint256 bidPenaltyPercentage,
        uint256 bidPenaltyPercentageBase
    ) internal pure returns (uint256 fineAmount, uint256 remaining) {
        fineAmount = (qualifyAmount * bidPenaltyPercentage) / bidPenaltyPercentageBase;
        remaining = qualifyAmount - fineAmount;
    }

    /**
     *@dev  call the royaltyInfo function in nft contract
     *@param _NFTContract NFT contract address
     *@param tokenId token id
     *@param _value  token price
     *@param _fee plateform fee Fraction.  the formula is (fees * 1000)/base
     *@param _feeBase plateform fee base
     *@return issuer original issuer address
     *@return royaltyAmount  the issuer total amount of tokens that he should recieve based on his share
     *@return fees  plateform fees
     *@return netPrice  amount that the seller will get after deducing the roylaity share and platform fees
     */

    function _getListingFinancialInfo(
        address _NFTContract,
        uint256 tokenId,
        uint256 _value,
        uint256 _fee,
        uint256 _feeBase
    )
        internal
        view
        returns (
            address issuer,
            uint256 royaltyAmount,
            uint256 fees,
            uint256 netPrice
        )
    {
        fees = _calcFees(_value, _fee, _feeBase);
        netPrice = _value - fees;
        // royalty check
        if (StartFiRoyalityLib._supportRoyalty(_NFTContract)) {
            (issuer, royaltyAmount) = StartFiRoyalityLib._getRoyaltyInfo(_NFTContract, tokenId, _value);
            if (royaltyAmount > 0 && issuer != address(0)) {
                netPrice = netPrice - royaltyAmount;
            }
        }
    }

    // function getUSDPriceInSTFI(uint256 _usdCap, uint256 _stfiCap) public pure returns (uint256 usdPrice) {
    //     require(_usdCap > 0 && _stfiCap > 0, 'StartFiFinanceLib: cap must be more than zero');
    //     // TODO: need to manage when 1 STFI is more than 1 USD ( dicimal issue in solidity)
    //     usdPrice = _stfiCap.wadDiv(_usdCap);
    // }
}
