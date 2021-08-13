// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.7;
pragma abicoder v2;
/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Bid
 * [ desc ] : contract handles all the bid related functions for marketplace
 */
contract MarketPlaceBid  {
 
    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
  struct Bid {
        bytes32 bidId;
        address nFTContract;
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
    /**
    * 
      * @dev   called by dapp or any contract to get info about a winner bid    
      * @param listingId listing id      
      * @return bidId bid id
      * @return bidder bidder address
      * @return nFTContract  nft contract address
      * @return tokenId nft token id
      * @return bidPrice bid price
      * @return isPurchased true if purchased
     */
function winnerBid(bytes32 listingId) view external returns (bytes32 bidId, address bidder, address nFTContract,uint256 tokenId,uint256 bidPrice,bool isPurchased ) {
  bidId=bidToListing[listingId].bidId;
  bidder=bidToListing[listingId].bidder;
  nFTContract=listingBids[listingId][bidder].nFTContract;
  tokenId=listingBids[listingId][bidder].tokenId;
  bidPrice=listingBids[listingId][bidder].bidPrice;
  isPurchased=listingBids[listingId][bidder].isPurchased;
}
    /**
    * 
      * @dev   called by dapp or any contract to get info about a given bidder in a listing    
      * @param listingId listing id      
      * @param bidder bidder address
      * @return bidId bid id
      * @return nFTContract  nft contract address
      * @return tokenId nft token id
      * @return bidPrice bid price
     */
function getAuctionBidDetails(bytes32 listingId,address bidder ) view external returns (bytes32 bidId,  address nFTContract,uint256 tokenId,uint256 bidPrice,bool isPurchased ) {
    bidId=listingBids[listingId][bidder].bidId;
   nFTContract=listingBids[listingId][bidder].nFTContract;
  tokenId=listingBids[listingId][bidder].tokenId;
  bidPrice=listingBids[listingId][bidder].bidPrice;
  isPurchased=listingBids[listingId][bidder].isPurchased;
}
 /******************************************* change state functions go here ********************************************************* */

    /**
    * @notice  all conditions and checks are made prior to this function
    * @dev  add new bid , update the latest bidder to be his bid
    * @param bidId bid id
    * @param listingId listing id 
    * @param tokenAddress nft contract address
    * @param bidder bidder address
    * @param tokenId token id 
    * @param bidPrice price 
    * @return true if it's done 
     */
function _bid(bytes32 bidId , bytes32 listingId, address tokenAddress,address bidder, uint256 tokenId, uint256 bidPrice) internal  returns(    bool){
 
            // where bid winner is the last bidder updated
            bidToListing[listingId]=WinningBid(bidId, bidder);
           listingBids[listingId][bidder]= Bid(bidId,tokenAddress,tokenId,bidPrice,false);
           return true;
}

 


}  

   
