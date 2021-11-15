// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to manage the special deals.
 * We might have some celebrities or big names who come to our platform though agreement, those users might need different terms and conditions and to enforce the agreement via smart contract we store them the contract and apply them in their deals
 * @title StartFi Marketplace Special Offer
 */
contract StartFiMarketPlaceSpecialOffer {
    /******************************************* decalrations go here ********************************************************* */

    mapping(address => conditions) internal offerTerms;
    struct conditions {
        uint256 fee; // 2.5% fees
        uint256 feeBase;
    }
    event NewOffer(
        address admin,
        address wallet,
        uint256 _fee, // 2.5% fees
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
        uint256 _fee, // 2.5% fees
        uint256 feeBase
    ) internal {
        require(offerTerms[wallet].fee == 0, 'StartFiMarketPlaceSpecialOffer: Already exisit');

        offerTerms[wallet] = conditions(_fee, feeBase);
    }

    function getOffer(address wallet)
        external
        view
        returns (
            uint256 _fee, // 2.5% fees
            uint256 _feeBase
        )
    {
        _fee = offerTerms[wallet].fee;

        _feeBase = offerTerms[wallet].feeBase;
    }
}
