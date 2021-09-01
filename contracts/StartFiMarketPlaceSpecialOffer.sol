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
        uint256 listqualifyPercentage;
        uint256 listqualifyPercentageBase;
        uint256 feeBase;
    }
    event NewOffer(
        address admin,
        address wallet,
        uint256 _delistAfter,
        uint256 _fee, // 2.5% fees
        uint256 _listqualifyPercentage,
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
        uint256 _listqualifyPercentage,
        uint256 _listqualifyPercentageBase,
        uint256 feeBase
    ) internal {
        require(offerTerms[wallet].fee == 0, 'StartFiMarketPlaceSpecialOffer: Already exisit');

        offerTerms[wallet] = conditions(
            _delistAfter,
            _fee,
            _listqualifyPercentage,
            _listqualifyPercentageBase,
            feeBase
        );
    }

    function getOffer(address wallet)
        external
        view
        returns (
            uint256 _delistAfter,
            uint256 _fee, // 2.5% fees
            uint256 _listqualifyPercentage,
            uint256 _listqualifyPercentageBase,
            uint256 _feeBase
        )
    {
        _delistAfter = offerTerms[wallet].delistAfter;
        _fee = offerTerms[wallet].fee;
        _listqualifyPercentage = offerTerms[wallet].listqualifyPercentage;
        _listqualifyPercentageBase = offerTerms[wallet].listqualifyPercentageBase;
        _feeBase = offerTerms[wallet].feeBase;
    }
}
