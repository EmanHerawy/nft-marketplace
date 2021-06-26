// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;
/**
 * @author Eman Herawy StartFi Team
 *@title  marketplace  bid contract
 * 
 */
contract MarketPlaceBid  {
 
    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
  struct Bid {
        bytes32 bidId;
        address nftAddress;
        uint256 tokenId;
        uint256 bidPrice;
        bool isPurchased;
       
    }
  struct WinningBid {
        bytes32 bidId;
        address bidder;       
    }
    // lisingId to bid key to bid details 
  mapping(bytes32 => mapping(address=>Bid)) internal listingBids;
  // track the bid latest bid id
  mapping (bytes32=>WinningBid) internal bidToListing;


 /******************************************* read state functions go here ********************************************************* */

// bid 
function _bid(bytes32 bidId , bytes32 listingId, address tokenAddress,address bidder, uint256 tokenId, uint256 bidPrice) internal  returns(    bool){
            // where bid winner is the last bidder updated
            bidToListing[listingId]=WinningBid(bidId, bidder);
           listingBids[listingId][bidder]= Bid(bidId,tokenAddress,tokenId,bidPrice,false);
           return true;
}

 


}  

   
