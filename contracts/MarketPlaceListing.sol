// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
contract MarketPlaceListing {
    // all fees are in perentage

    // store every listed item here
    bytes32[] public listings;

    constructor() {}

    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
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

    // track the Listinger total amount of Listings
    // mapping (address=>uint256) private userTotalListings;
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

    ///**
    // *
    //   * @dev   called by dapp or any contract to get info about a gevin listing
    //   * @param index index in listing array

    //   * @return listingId in that index
    //   * @return tokenAddress  nft contract address
    //   * @return tokenId NFT token Id
    //   * @return listingPrice initial price or minimum price that the seller can accept
    //   * @return endPrice purchase price
    //   * @return seller  nft seller address
    //   * @return buyer  nft buyer address
    //   * @return iseBdEnabeled true if auction enabled
    //   * @return isSellForEnabled true if auction enable direct selling
    //   * @return releaseTime  when auction ends
    //   * @return disputeTime  when auction creator can dispute and take the insurance from the bad actor 'bidWinner'
    //   * @return insuranceAmount  amount of token locked as qualify for any bidder wants bid
    //   * @return sellFor if sell for enabled for auction, this should be more than zero
    //   * @return status in number {Sold,OnMarket, onAuction,Canceled}
    //  */
    // function getListingDetailsByIndex(uint256 index)
    //     external
    //     view
    //     returns (
    //         bytes32 listingId,
    //         address tokenAddress,
    //         uint256 tokenId,
    //         uint256 listingPrice,
    //         uint256 endPrice,
    //         address seller,
    //         address buyer,
    //         bool iseBdEnabeled,
    //         bool isSellForEnabled,
    //         uint256 releaseTime,
    //         uint256 disputeTime,
    //         uint256 insuranceAmount,
    //         uint256 sellFor,
    //         uint256 status
    //     )
    // {
    //     listingId = listings[index];
    //     tokenAddress = _tokenListings[listingId].token;
    //     tokenId = _tokenListings[listingId].tokenId;
    //     listingPrice = _tokenListings[listingId].listingPrice;
    //     endPrice = _tokenListings[listingId].endPrice;
    //     seller = _tokenListings[listingId].seller;
    //     buyer = _tokenListings[listingId].buyer;
    //     iseBdEnabeled = _tokenListings[listingId].iseBdEnabeled;
    //     isSellForEnabled = _tokenListings[listingId].isSellForEnabled;
    //     releaseTime = _tokenListings[listingId].releaseTime;
    //     disputeTime = _tokenListings[listingId].disputeTime;
    //     insuranceAmount = _tokenListings[listingId].insuranceAmount;
    //     sellFor = _tokenListings[listingId].sellFor;
    //     status = uint256(_tokenListings[listingId].status);
    // }
}
