// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import '../library/StartFiFinanceLib.sol';

/**
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
interface IMarketPlaceFixedPriceItem {
    struct Listing {
        address token;
        uint256 tokenId;
        uint256 listingPrice;
        address seller;
        address buyer;
        ListingStatus status;
    }
    enum ListingStatus {
        Sold,
        OnMarket,
        Canceled
    }

    /******************************************* read state functions go here ********************************************************* */
    /**
    * 
      * @dev   called by dapp or any contract to get info about a gevin listing    
      * @param listingId listing id      

      * @return tokenAddress  nft contract address
      * @return seller  nft seller address
      * @return buyer  nft buyer address
      * @return tokenId NFT token Id 
      * @return listingPrice initial price or minimum price that the seller can accept
       * @return status in number {Sold,OnMarket, onAuction,Canceled}
     */
    function getListingDetails(bytes32 listingId)
        external
        view
        returns (
            address tokenAddress,
            address seller,
            address buyer,
            uint256 tokenId,
            uint256 listingPrice,
            uint256 status
        );

    function getSeller(bytes32 listingId) external view returns (address);

    /** external functions that changes the state go here  */
    /// @dev only called by marketplace contract

    function deList(bytes32 listingId, address sender) external returns (address, uint256);

    function listItemOnMarket(
        bytes32 listId,
        address token,
        address seller,
        uint256 tokenId,
        uint256 listingPrice
    ) external returns (bool);

    function buyNow(
        bytes32 listingId,
        address buyer,
        uint256 cap,
        bool isKyced
    )
        external
        returns (
            StartFiFinanceLib.ShareOutput memory _output,
            address token,
            address seller,
            uint256 tokenId,
            uint256 price
        );
}
