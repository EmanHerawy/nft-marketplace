// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to manage the deal cap to keep all our transaction regulated
 *  Startfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the purchase transaction can't be proceed unless this deal is approved by Startfi by calling [approveDeal]
 * @title StartFi Marketplace Cap
 */
contract StartFiMarketPlaceCap {
    /******************************************* decalrations go here ********************************************************* */

    uint256 public usdCap;
    uint256 public stfiCap;
    uint256 public stfiUsdt; // how many STFI per 1 usd?
    mapping(bytes32 => bool) internal kycedDeals;

    /******************************************* read functions go here ********************************************************* */

    function isApprovedDeal(bytes32 listingId) public view returns (bool status) {
        status = kycedDeals[listingId];
    }

    /******************************************* state functions go here ********************************************************* */
    /**
     * @dev update the cap, called by child contracts .
     *
     *
     *
     * Requirements:
     *
     * - the `_usdCap` must not be empty.
     */
    function _setCap(uint256 _usdCap) internal {
        require(_usdCap > 0, 'StartFiMarketplaceCap: cap must be more than zero');
        usdCap = _usdCap;
    }
}
