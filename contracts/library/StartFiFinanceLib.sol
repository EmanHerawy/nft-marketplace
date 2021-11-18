// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import './StartFiRoyalityLib.sol';

import './SafeDecimalMath.sol';

library StartFiFinanceLib {
    using SafeDecimalMath for uint256;

    struct ShareInput {
        address token;
        uint256 tokenId;
        uint256 price;
        uint256 fee;
        uint256 feeBase;
    }
    struct ShareOutput {
        address issuer;
        uint256 royaltyAmount;
        uint256 fees;
        uint256 netPrice;
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
        // round decimal to the nearst value
        fees = price.multiplyDecimalRound((_fee.divideDecimal(_feeBase * 100)));
    }

    /**
      @dev calculat the platform share when seller call disput
    *@param insuranceAmount  : seller defind value to be staked in order to participate in a gevin auction
    * @return fineAmount the value that the platform will get
    * @return remaining the value that the auction woner will get
     */
    function _calcBidDisputeFees(uint256 insuranceAmount)
        internal
        pure
        returns (uint256 fineAmount, uint256 remaining)
    {
        fineAmount = insuranceAmount.divideDecimalRound(2 ether); // divided by 2 * 18 decimal

        remaining = insuranceAmount - fineAmount;
    }

    function _calcShare(uint256 numerator, uint256 donomirator) internal pure returns (uint256 share) {
        share = numerator.divideDecimalRound(donomirator);
    }

    /**
     *@dev  call the royaltyInfo function in nft contract
     *@param _input of type ShareInput
     *@return _output of type ShareOutput
     */

    function _getListingFinancialInfo(ShareInput memory _input) internal view returns (ShareOutput memory _output) {
        _output.fees = _calcFees(_input.price, _input.fee, _input.feeBase);
        _output.netPrice = _input.price - _output.fees;
        // royalty check
        if (StartFiRoyalityLib._supportRoyalty(_input.token)) {
            (_output.issuer, _output.royaltyAmount) = StartFiRoyalityLib._getRoyaltyInfo(
                _input.token,
                _input.tokenId,
                _input.price
            );
            if (_output.royaltyAmount > 0 && _output.issuer != address(0)) {
                _output.netPrice = _output.netPrice - _output.royaltyAmount;
            }
        }
    }
}
