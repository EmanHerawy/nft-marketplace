// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to manage the deal cap to keep all our transaction regulated
 * @title StartFi Marketplace Cap
 */
contract StartFiMarketPlaceCap {
    /******************************************* decalrations go here ********************************************************* */

    uint256 public usdCap;
    uint256 public stfiCap;
    mapping(bytes32 => bool) kycedDeals;

    /******************************************* read functions go here ********************************************************* */

    function isApprovedDeal(bytes32 listingId) public view returns (bool status) {
        status = kycedDeals[listingId];
    }

    /******************************************* state functions go here ********************************************************* */
    function _setCap(uint256 _usdCap, uint256 _stfiCap) internal {
        require(_usdCap > 0 && _stfiCap > 0, 'StartFiMarketplaceCap: cap must be more than zero');
        usdCap = _usdCap;
        stfiCap = _stfiCap;
    }
}
