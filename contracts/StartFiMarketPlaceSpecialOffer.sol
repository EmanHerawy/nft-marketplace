// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to manage the special deals
 * @title StartFi Marketplace Special Offer
 */
contract StartFiMarketPlaceSpecialOffer {
    /******************************************* decalrations go here ********************************************************* */

    mapping(address => conditions) offerTerms;
    struct conditions {
        uint256 delistAfter;
        uint256 fee; // 2.5% fees
        uint256 bidPenaltyPercentage; // 1 %
        uint256 delistFeesPercentage;
        uint256 listqualifyPercentage;
        uint256 bidPenaltyPercentageBase;
        uint256 delistFeesPercentageBase;
        uint256 listqualifyPercentageBase;
        uint256 feeBase;
    }
    event NewOffer(
        address admin,
        address wallet,
        uint256 _delistAfter,
        uint256 _fee, // 2.5% fees
        uint256 _bidPenaltyPercentage, // 1 %
        uint256 _delistFeesPercentage,
        uint256 _listqualifyPercentage,
        uint256 _bidPenaltyPercentageBase,
        uint256 _delistFeesPercentageBase,
        uint256 _listqualifyPercentageBase,
        uint256 _feeBase
    );

    /******************************************* read functions go here ********************************************************* */

    /******************************************* state functions go here ********************************************************* */
    /**
     * @dev add new special offer.
     * called by child contracts
     *
     *
     * Requirements:
     *
     * -  must  be new offer.
     */
    function _addOffer(
        address wallet,
        uint256 _delistAfter,
        uint256 _fee, // 2.5% fees
        uint256 _bidPenaltyPercentage, // 1 %
        uint256 _delistFeesPercentage,
        uint256 _listqualifyPercentage,
        uint256 _bidPenaltyPercentageBase,
        uint256 _delistFeesPercentageBase,
        uint256 _listqualifyPercentageBase,
        uint256 _feeBase
    ) internal {
        require(offerTerms[wallet].fee == 0, 'StartFiMarketPlaceSpecialOffer: Already exisit');

        offerTerms[wallet] = conditions(
            _delistAfter,
            _fee,
            _bidPenaltyPercentage,
            _delistFeesPercentage,
            _listqualifyPercentage,
            _bidPenaltyPercentageBase,
            _delistFeesPercentageBase,
            _listqualifyPercentageBase,
            _feeBase
        );
    }

    function getOffer(address wallet)
        external
        view
        returns (
            uint256 _delistAfter,
            uint256 _fee, // 2.5% fees
            uint256 _bidPenaltyPercentage, // 1 %
            uint256 _delistFeesPercentage,
            uint256 _listqualifyPercentage,
            uint256 _bidPenaltyPercentageBase,
            uint256 _delistFeesPercentageBase,
            uint256 _listqualifyPercentageBase,
            uint256 _feeBase
        )
    {
        _delistAfter = offerTerms[wallet].delistAfter;
        _fee = offerTerms[wallet].fee;
        _bidPenaltyPercentage = offerTerms[wallet].bidPenaltyPercentage;
        _delistFeesPercentage = offerTerms[wallet].delistFeesPercentage;
        _listqualifyPercentage = offerTerms[wallet].listqualifyPercentage;
        _delistFeesPercentageBase = offerTerms[wallet].delistFeesPercentageBase;
        _bidPenaltyPercentageBase = offerTerms[wallet].bidPenaltyPercentageBase;
        _listqualifyPercentageBase = offerTerms[wallet].listqualifyPercentageBase;
        _feeBase = offerTerms[wallet].feeBase;
    }
}
