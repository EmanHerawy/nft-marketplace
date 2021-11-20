// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import './StartFiMarketPlaceFinance.sol';

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to manage the deal cap to keep all our transaction regulated
 *  Startfi is MarketPlaceBid entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the purchase transaction can't be proceed unless this deal is approved by Startfi by calling [approveDeal]
 * @title StartFi Marketplace Cap
 */
contract StartFiMarketPlaceCap is StartFiMarketPlaceFinance {
    /******************************************* decalrations go here ********************************************************* */

    uint256 internal _usdCap;
    uint256 internal _stfiCap;
    uint256 internal _stfiUsdt; // how many STFI per 1 usd?
    mapping(bytes32 => bool) internal kycedDeals;
    event HandelKyc(bytes32 indexed listId, address approver, bool status, uint256 timestamp);

    /******************************************* read functions go here ********************************************************* */

    function isApprovedDeal(bytes32 listingId) public view returns (bool status) {
        status = kycedDeals[listingId];
    }

    /******************************************* state functions go here ********************************************************* */
    function usdCap() external view returns (uint256) {
        return _usdCap;
    }

    function stfiCap() external view returns (uint256) {
        return _stfiCap;
    }

    function stfiUsdt() external view returns (uint256) {
        return _stfiUsdt;
    }

    /**
     *  @dev only called by `owner` to update the cap
     * @param usdCap_  the new fees value to be stored
     */
    function setUsdCap(uint256 usdCap_) external onlyOwner whenPaused {
        require(usdCap_ > 0, 'StartFiMarketplaceCap: cap must be more than zero');
        _usdCap = usdCap_;
    }

    /**
     *  @dev only called by  `priceFeeds` to update the STFI/usdt price
     * @param _stfiPrice  the new stfi price per usdt
     */
    function setPrice(uint256 _stfiPrice) external {
        require(hasRole(PRICE_FEEDER_ROLE, _msgSender()), 'StartFiMarketPlace: UnAuthorized');
        // set
        _stfiUsdt = _stfiPrice;
        _stfiCap = _stfiPrice * _usdCap;
    }
}
