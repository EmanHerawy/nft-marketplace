// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;

/**
 * @author Eman Herawy StartFi Team
 *@title  marketplace  Listing contract
 * 
 */
contract MarketPlaceListing  {
  // all fees are in perentage 

      // delist after 6 month
      uint256 public delistAfter= 6*30 days;
    constructor(
     
    )  {
      
    }
    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
  struct Listing {
        address nftAddress;
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
        ListingStatus status ;
    }
    enum ListingStatus {Sold,OnMarket, onAuction,Canceled }
    // listing key  to lisitng details 
   mapping(bytes32=>Listing) internal _tokenListings;
  // track the Listinger total amount of Listings
  // mapping (address=>uint256) private userTotalListings;
  /******************************************* read state functions go here ********************************************************* */
function getListingDetails(bytes32 listingId ) view external returns ( address nftAddress,        uint256 tokenId,uint256 listingPrice,uint256 endPrice,address seller,address buyer,bool bedEnabeled,bool sellForEnabled,uint256 releaseTime,uint256 qualifyAmount,uint256 sellFor,uint status ) {
      nftAddress=_tokenListings[listingId].nftAddress ;
      tokenId=_tokenListings[listingId].tokenId ;
      listingPrice=_tokenListings[listingId].listingPrice ;
      endPrice=_tokenListings[listingId]. endPrice;
      seller=_tokenListings[listingId]. seller;
      buyer=_tokenListings[listingId].buyer ;
      bedEnabeled=_tokenListings[listingId].bedEnabeled ;
      sellForEnabled=_tokenListings[listingId].sellForEnabled ;
      releaseTime=_tokenListings[listingId]. releaseTime;
      qualifyAmount=_tokenListings[listingId].qualifyAmount ;
      sellFor=_tokenListings[listingId]. sellFor;
      status=uint(_tokenListings[listingId]. status);
}
// list 
function _listOnMarketPlace( 
        bytes32 listId,
        address nftAddress,
        address buyer,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 releaseTime,
         uint256 qualifyAmount
        ) internal returns (bool)
        {
  
              _tokenListings[listId]=Listing(nftAddress,tokenId,listingPrice,0,address(0),buyer,
              false,false,releaseTime,qualifyAmount,0,ListingStatus.OnMarket);
              return true;
        }
// delist 
function _creatAuction( 
        bytes32 listId,
        address nftAddress,
        address buyer,
        uint256 tokenId,
        uint256 listingPrice,     
        bool sellForEnabled,
        uint256 sellFor,
        uint256 releaseTime,
        uint256 qualifyAmount
        ) internal returns (bool)
        {
  
              _tokenListings[listId]=Listing(nftAddress,tokenId,listingPrice,0,address(0),buyer,
              true,sellForEnabled,releaseTime,qualifyAmount,sellFor,ListingStatus.onAuction);
              return true;
        }
        function _finalizeListing(  bytes32 listId,address seller, ListingStatus status) internal  {
          _tokenListings[listId].status=status;
          if(seller!=address(0)){
             _tokenListings[listId].seller=seller;
          }
          
        }
function _deList(bytes32 listingId) internal {
  _tokenListings[listingId].status=ListingStatus.Canceled;
}

function _changeDelistAfter(uint256 duration) internal {
 delistAfter =duration;
}

}  

   
