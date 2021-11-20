// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 *desc   contract to manage the deal cap to keep all our transaction regulated
 *  Startfi is MarketPlaceBid entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the purchase transaction can't be proceed unless this deal is approved by Startfi by calling [approveDeal]
 * @title StartFi Marketplace Cap
 */
interface IStartFiMarketPlace {
    /******************************************* decalrations go here ********************************************************* */

    /******************************************* read functions go here ********************************************************* */

    function isApprovedDeal(bytes32 listingId) external view returns (bool status);

    function getUserReserved(address user) external view returns (uint256);

    function usdCap() external view returns (uint256);

    function stfiCap() external view returns (uint256);

    function stfiUsdt() external view returns (uint256);

    function getFees(address seller) external view returns (uint256 fee, uint256 feeBase);

    /******************************************* state functions go here ********************************************************* */

    // /**
    //  *  @dev only called by `owner` to update the cap
    //  * @param _usdCap  the new fees value to be stored
    //  */
    // function setUsdCap(uint256 _usdCap) external;

    // /**
    //  *  @dev only called by  `priceFeeds` to update the STFI/usdt price
    //  * @param _stfiPrice  the new stfi price per usdt
    //  */
    // function setPrice(uint256 _stfiPrice) external;
}
