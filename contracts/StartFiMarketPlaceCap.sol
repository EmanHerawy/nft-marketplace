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

    uint256 public usdCap;
    uint256 public stfiCap;
    uint256 public stfiUsdt; // how many STFI per 1 usd?
    mapping(bytes32 => bool) internal kycedDeals;
    event HandelKyc(bytes32 indexed listId, address approver, bool status, uint256 timestamp);

    /******************************************* read functions go here ********************************************************* */

    function isApprovedDeal(bytes32 listingId) public view returns (bool status) {
        status = kycedDeals[listingId];
    }

    /******************************************* state functions go here ********************************************************* */

    /**
     *  @dev only called by `owner` to update the cap
     * @param _usdCap  the new fees value to be stored
     */
    function setUsdCap(uint256 _usdCap) external onlyOwner whenPaused {
        require(_usdCap > 0, 'StartFiMarketplaceCap: cap must be more than zero');
        usdCap = _usdCap;
    }

    /**
     *  @dev only called by  `priceFeeds` to update the STFI/usdt price
     * @param _stfiPrice  the new stfi price per usdt
     */
    function setPrice(uint256 _stfiPrice) external {
        require(hasRole(PRICE_FEEDER_ROLE, _msgSender()), 'StartFiMarketPlace: UnAuthorized');
        // set
        stfiUsdt = _stfiPrice;
        stfiCap = _stfiPrice * usdCap;
    }
}
