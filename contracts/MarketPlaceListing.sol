// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
pragma abicoder v2;

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
contract MarketPlaceListing {
    // all fees are in perentage

    uint256 public fulfillDuration = 3 days;
    // store every listed item here
    bytes32[] public listings;

    constructor() {}

    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
    struct Listing {
        address nFTContract;
        uint256 tokenId;
        uint256 listingPrice;
        uint256 endPrice;
        address seller;
        address buyer;
        bool iseBdEnabeled;
        bool isSellForEnabled;
        // only if bed and sell for enabled
        uint256 releaseTime;
        uint256 disputeTime; // only in auction
        uint256 insurancAmount; // if it is not auction, this represents the inusrance seller has to put, if auction , this represents the insurance bidder has to put
        uint256 sellFor;
        ListingStatus status;
    }
    enum ListingStatus {
        Sold,
        OnMarket,
        onAuction,
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
      * @return tokenId NFT token Id 
      * @return listingPrice initial price or minimum price that the seller can accept
      * @return endPrice purchase price
      * @return seller  nft seller address
      * @return buyer  nft buyer address
      * @return iseBdEnabeled true if auction enabled  
      * @return isSellForEnabled true if auction enable direct selling
      * @return releaseTime  when auction ends
      * @return disputeTime  when auction creator can dispute and take the insurance from the bad actor 'bidWinner' 
      * @return insurancAmount  amount of token locked as qualify for any bidder wants bid 
      * @return sellFor if sell for enabled for auction, this should be more than zero
      * @return status in number {Sold,OnMarket, onAuction,Canceled}
     */
    function getListingDetails(bytes32 listingId)
        external
        view
        returns (
            address tokenAddress,
            uint256 tokenId,
            uint256 listingPrice,
            uint256 endPrice,
            address seller,
            address buyer,
            bool iseBdEnabeled,
            bool isSellForEnabled,
            uint256 releaseTime,
            uint256 disputeTime,
            uint256 insurancAmount,
            uint256 sellFor,
            uint256 status
        )
    {
        tokenAddress = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        listingPrice = _tokenListings[listingId].listingPrice;
        endPrice = _tokenListings[listingId].endPrice;
        seller = _tokenListings[listingId].seller;
        buyer = _tokenListings[listingId].buyer;
        iseBdEnabeled = _tokenListings[listingId].iseBdEnabeled;
        isSellForEnabled = _tokenListings[listingId].isSellForEnabled;
        releaseTime = _tokenListings[listingId].releaseTime;
        disputeTime = _tokenListings[listingId].disputeTime;
        insurancAmount = _tokenListings[listingId].insurancAmount;
        sellFor = _tokenListings[listingId].sellFor;
        status = uint256(_tokenListings[listingId].status);
    }

    /**
    * 
      * @dev   called by dapp or any contract to get info about a gevin listing    
      * @param index index in listing array      

      * @return listingId in that index 
      * @return tokenAddress  nft contract address
      * @return tokenId NFT token Id 
      * @return listingPrice initial price or minimum price that the seller can accept
      * @return endPrice purchase price
      * @return seller  nft seller address
      * @return buyer  nft buyer address
      * @return iseBdEnabeled true if auction enabled  
      * @return isSellForEnabled true if auction enable direct selling
      * @return releaseTime  when auction ends
      * @return disputeTime  when auction creator can dispute and take the insurance from the bad actor 'bidWinner' 
      * @return insurancAmount  amount of token locked as qualify for any bidder wants bid 
      * @return sellFor if sell for enabled for auction, this should be more than zero
      * @return status in number {Sold,OnMarket, onAuction,Canceled}
     */
    function getListingDetailsByIndex(uint256 index)
        external
        view
        returns (
            bytes32 listingId,
            address tokenAddress,
            uint256 tokenId,
            uint256 listingPrice,
            uint256 endPrice,
            address seller,
            address buyer,
            bool iseBdEnabeled,
            bool isSellForEnabled,
            uint256 releaseTime,
            uint256 disputeTime,
            uint256 insurancAmount,
            uint256 sellFor,
            uint256 status
        )
    {
        listingId = listings[index];
        tokenAddress = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        listingPrice = _tokenListings[listingId].listingPrice;
        endPrice = _tokenListings[listingId].endPrice;
        seller = _tokenListings[listingId].seller;
        buyer = _tokenListings[listingId].buyer;
        iseBdEnabeled = _tokenListings[listingId].iseBdEnabeled;
        isSellForEnabled = _tokenListings[listingId].isSellForEnabled;
        releaseTime = _tokenListings[listingId].releaseTime;
        disputeTime = _tokenListings[listingId].disputeTime;
        insurancAmount = _tokenListings[listingId].insurancAmount;
        sellFor = _tokenListings[listingId].sellFor;
        status = uint256(_tokenListings[listingId].status);
    }

    // list

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev  add new item for sale in marketplace
     * @param listId listing id
     * @param tokenAddress nft contract address
     * @param seller seller address
     * @param tokenId token id
     * @param listingPrice min price

     * @return true if it's done
     */
    function _listOnMarketPlace(
        bytes32 listId,
        address tokenAddress,
        address seller,
        uint256 tokenId,
        uint256 listingPrice
    ) internal returns (bool) {
        _tokenListings[listId] = Listing(
            tokenAddress,
            tokenId,
            listingPrice,
            0,
            seller,
            address(0),
            false,
            false,
            block.timestamp,
            0,
            0,
            0,
            ListingStatus.OnMarket
        );
        return true;
    }

    /**
     * @notice  all conditions and checks are made prior to this function
     * @dev  add new auction
     * @param listId listing id
     * @param tokenAddress nft contract address
     * @param seller seller address
     * @param tokenId token id
     * @param listingPrice min price
     * @param isSellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if isSellForEnabled=true
     * @param releaseTime  when auction ends
     * @param insurancAmount  amount of token locked as qualify for any bidder wants bid
     * @return true if it's done
     */
    function _creatAuction(
        bytes32 listId,
        address tokenAddress,
        address seller,
        uint256 tokenId,
        uint256 listingPrice,
        bool isSellForEnabled,
        uint256 sellFor,
        uint256 releaseTime,
        uint256 insurancAmount
    ) internal returns (bool) {
        _tokenListings[listId] = Listing(
            tokenAddress,
            tokenId,
            listingPrice,
            0,
            seller,
            address(0),
            true,
            isSellForEnabled,
            releaseTime,
            releaseTime + fulfillDuration,
            insurancAmount,
            sellFor,
            ListingStatus.onAuction
        );
        return true;
    }

    function _finalizeListing(
        bytes32 listId,
        address buyer,
        ListingStatus status
    ) internal {
        _tokenListings[listId].status = status;
        if (buyer != address(0)) {
            _tokenListings[listId].buyer = buyer;
        }
    }
}
