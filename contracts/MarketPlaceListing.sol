// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
contract MarketPlaceListing {
    // store every listed item here
    bytes32[] public listings;

    constructor() {}

    struct Listing {
        address token;
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 listingPrice;
        // only if bed and sell for enabled
        uint256 releaseTime;
        uint256 disputeTime; // only in auction
        uint256 insuranceAmount; // if it is not auction, this represents the inusrance seller has to put, if auction , this represents the insurance bidder has to put
        uint256 minimumBid;
        ListingType listingType;
        ListingStatus status;
    }
    enum ListingType {
        Auction,
        FixedPrice,
        AuctionForSale
    }
    enum ListingStatus {
        Sold,
        OnMarket,
        Canceled
    }
    // listing key  to lisitng details
    mapping(bytes32 => Listing) internal _tokenListings;

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
  
      * @return releaseTime  when auction ends
      * @return disputeTime  when auction creator can dispute and take the insurance from the bad actor 'bidWinner'
      * @return insuranceAmount  amount of token locked as qualify for any bidder wants bid
      * @return minimumBid if sell for enabled for auction, this should be more than zero
      * @return listingType in number { Auction,FixedPrice,AuctionForSale}
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
            uint256 releaseTime,
            uint256 disputeTime,
            uint256 insuranceAmount,
            uint256 minimumBid,
            uint256 listingType,
            uint256 status
        )
    {
        tokenAddress = _tokenListings[listingId].token;
        seller = _tokenListings[listingId].seller;
        buyer = _tokenListings[listingId].buyer;
        tokenId = _tokenListings[listingId].tokenId;
        listingPrice = _tokenListings[listingId].listingPrice;

        releaseTime = _tokenListings[listingId].releaseTime;
        disputeTime = _tokenListings[listingId].disputeTime;
        insuranceAmount = _tokenListings[listingId].insuranceAmount;
        minimumBid = _tokenListings[listingId].minimumBid;
        status = uint256(_tokenListings[listingId].status);
        listingType = uint256(_tokenListings[listingId].listingType);
    }
}
