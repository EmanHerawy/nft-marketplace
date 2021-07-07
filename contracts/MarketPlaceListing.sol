// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
contract MarketPlaceListing {
    // all fees are in perentage

    // delist after 6 month
    uint256 public delistAfter = 6 * 30 days; 

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
        bool bedEnabeled;
        bool sellForEnabled;
        // only if bed and sell for enabled
        uint256 releaseTime;
        uint256 qualifyAmount;
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
      * @return bedEnabeled true if auction enabled  
      * @return sellForEnabled true if auction enable direct selling
      * @return releaseTime  when auction ends
      * @return qualifyAmount  amount of token locked as qualify for any bidder wants bid 
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
            bool bedEnabeled,
            bool sellForEnabled,
            uint256 releaseTime,
            uint256 qualifyAmount,
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
        bedEnabeled = _tokenListings[listingId].bedEnabeled;
        sellForEnabled = _tokenListings[listingId].sellForEnabled;
        releaseTime = _tokenListings[listingId].releaseTime;
        qualifyAmount = _tokenListings[listingId].qualifyAmount;
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
     * @param releaseTime  time to delist for free
     * @return true if it's done
     */
    function _listOnMarketPlace(
        bytes32 listId,
        address tokenAddress,
        address seller,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 releaseTime
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
            releaseTime,
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
     * @param sellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if sellForEnabled=true
     * @param releaseTime  when auction ends
     * @param qualifyAmount  amount of token locked as qualify for any bidder wants bid
     * @return true if it's done
     */
    function _creatAuction(
        bytes32 listId,
        address tokenAddress,
        address seller,
        uint256 tokenId,
        uint256 listingPrice,
        bool sellForEnabled,
        uint256 sellFor,
        uint256 releaseTime,
        uint256 qualifyAmount
    ) internal returns (bool) {
        _tokenListings[listId] = Listing(
            tokenAddress,
            tokenId,
            listingPrice,
            0,
            seller,
            address(0),
            true,
            sellForEnabled,
            releaseTime,
            qualifyAmount,
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

    /**
     *  @notice  all conditions and checks are made prior to this function
     * @dev  delist an item by mark status as canceled
     * @param listingId listing id
     *
     */
    function _deList(bytes32 listingId) internal {
        _tokenListings[listingId].status = ListingStatus.Canceled;
    }

    /**
     *  @notice  all conditions and checks are made prior to this function
     * @dev  change the duration of which user can delist thier nfts for free after it
     * @param duration in seconds , eg 30 days in desconds
     *
     */
    function _changeDelistAfter(uint256 duration) internal {
        delistAfter = duration;
    }
}
