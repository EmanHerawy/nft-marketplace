// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Bid
 * [ desc ] : contract handles all the bid related functions for marketplace
 */
contract MarketPlaceAuction {
    struct Bid {
        bytes32 bidId;
        address token;
        uint256 tokenId;
        uint256 bidPrice;
        bool isPurchased;
        bool isStakeReserved; // ture till the bidder free
    }
    struct WinningBid {
        bytes32 bidId;
        address bidder;
    }
    struct Listing {
        address token;
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 minimumBid;
        uint256 sellingPrice;
        uint256 isSellForEnabled; // 0 if false , 1 if true
        // only if bed and sell for enabled
        uint256 releaseTime;
        uint256 disputeTime; // only in auction
        uint256 insuranceAmount; // if it is not auction, this represents the inusrance seller has to put, if auction , this represents the insurance bidder has to put
        uint256 sellFor;
        ListingStatus status;
    }
    enum ListingStatus {
        Sold,
        OnMarket,
        Canceled
    }
    // lisingId to bid key to bid details
    mapping(bytes32 => mapping(address => Bid)) internal listingBids;
    // track the bid latest bid id
    mapping(bytes32 => WinningBid) internal bidToListing;
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
      * @return minimumBid initial price or minimum price that the seller can accept
      * @return sellingPrice purchase price

       * @return isSellForEnabled true if auction enable direct selling
      * @return releaseTime  when auction ends
      * @return disputeTime  when auction creator can dispute and take the insurance from the bad actor 'bidWinner' 
      * @return insuranceAmount  amount of token locked as qualify for any bidder wants bid 
      * @return sellFor if sell for enabled for auction, this should be more than zero
      * @return status in number {Sold,OnMarket, Canceled}
     */
    function getListingDetails(bytes32 listingId)
        external
        view
        returns (
            address tokenAddress,
            address seller,
            address buyer,
            uint256 tokenId,
            uint256 minimumBid,
            uint256 sellingPrice,
            uint256 isSellForEnabled,
            uint256 releaseTime,
            uint256 disputeTime,
            uint256 insuranceAmount,
            uint256 sellFor,
            uint256 status
        )
    {
        tokenAddress = _tokenListings[listingId].token;
        tokenId = _tokenListings[listingId].tokenId;
        minimumBid = _tokenListings[listingId].minimumBid;
        sellingPrice = _tokenListings[listingId].sellingPrice;
        seller = _tokenListings[listingId].seller;
        buyer = _tokenListings[listingId].buyer;
        isSellForEnabled = _tokenListings[listingId].isSellForEnabled;
        releaseTime = _tokenListings[listingId].releaseTime;
        disputeTime = _tokenListings[listingId].disputeTime;
        insuranceAmount = _tokenListings[listingId].insuranceAmount;
        sellFor = _tokenListings[listingId].sellFor;
        status = uint256(_tokenListings[listingId].status);
    }

    /**
     *
     * @dev   called by dapp or any contract to get info about a winner bid
     * @param listingId listing id
     * @return bidId bid id
     * @return bidder bidder address
     * @return token  nft contract address
     * @return tokenId nft token id
     * @return bidPrice bid price
     * @return isPurchased true if purchased
     * @return isStakeReserved true if the reserve is free
     */
    function winnerBid(bytes32 listingId)
        external
        view
        returns (
            bytes32 bidId,
            address bidder,
            address token,
            uint256 tokenId,
            uint256 bidPrice,
            bool isPurchased,
            bool isStakeReserved
        )
    {
        bidId = bidToListing[listingId].bidId;
        bidder = bidToListing[listingId].bidder;
        token = listingBids[listingId][bidder].token;
        tokenId = listingBids[listingId][bidder].tokenId;
        bidPrice = listingBids[listingId][bidder].bidPrice;
        isPurchased = listingBids[listingId][bidder].isPurchased;
        isStakeReserved = listingBids[listingId][bidder].isStakeReserved;
    }

    /**
     *
     * @dev   called by dapp or any contract to get info about a given bidder in a listing
     * @param listingId listing id
     * @param bidder bidder address
     * @return bidId bid id
     * @return token  nft contract address
     * @return tokenId nft token id
     * @return bidPrice bid price
     * @return isPurchased true if purchased
     * @return isStakeReserved true if the reserve is free
     */
    function getAuctionBidDetails(bytes32 listingId, address bidder)
        external
        view
        returns (
            bytes32 bidId,
            address token,
            uint256 tokenId,
            uint256 bidPrice,
            bool isPurchased,
            bool isStakeReserved
        )
    {
        bidId = listingBids[listingId][bidder].bidId;
        token = listingBids[listingId][bidder].token;
        tokenId = listingBids[listingId][bidder].tokenId;
        bidPrice = listingBids[listingId][bidder].bidPrice;
        isPurchased = listingBids[listingId][bidder].isPurchased;
        isStakeReserved = listingBids[listingId][bidder].isStakeReserved;
    }

    /******************************************* change state functions go here ********************************************************* */
}
