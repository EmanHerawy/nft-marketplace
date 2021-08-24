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
        uint256 _feeFraction,
        uint256 _feeBase
    ) internal pure returns (uint256 fees) {
        fees = price.wadMul(_feeFraction).wadDiv(_feeBase);
    }

    /**
     @dev calculat the platform fine amount when seller delist before time
    *@param listingPrice  : item listing price
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

    function _getListingFinancialInfo(
        address _NFTContract,
        uint256 tokenId,
        uint256 bidPrice,
        uint256 _feeFraction,
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
        fees = _calcFees(bidPrice, _feeFraction, _feeBase);
        netPrice = bidPrice - fees;
        // royalty check
        if (StartFiRoyalityLib._supportRoyalty(_NFTContract)) {
            (issuer, royaltyAmount) = StartFiRoyalityLib._getRoyaltyInfo(_NFTContract, tokenId, bidPrice);
            if (royaltyAmount > 0 && issuer != address(0)) {
                netPrice = netPrice - royaltyAmount;
            }
        }
    }

    function getUSDPriceInSTFI(uint256 _usdCap, uint256 _stfiCap) public pure returns (uint256 usdPrice) {
        require(_usdCap > 0 && _stfiCap > 0, 'StartFiFinanceLib: cap must be more than zero');
        // TODO: need to manage when 1 STFI is more than 1 USD ( dicimal issue in solidity)
        usdPrice = _stfiCap.wadDiv(_usdCap);
    }
}
