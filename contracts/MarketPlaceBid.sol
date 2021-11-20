// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
pragma abicoder v2;

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Bid
 * [ desc ] : contract handles all the bid related functions for marketplace
 */
contract MarketPlaceBid {
    // using Address for address;
    // using EnumerableSet for EnumerableSet.UintSet;
    // using EnumerableSet for EnumerableSet.AddressSet;
    struct Bid {
        bytes32 bidId;
        uint256 bidPrice;
        bool isPurchased;
        bool isStakeReserved; // ture till the bidder free
    }
    struct WinningBid {
        bytes32 bidId;
        address bidder;
    }
    // lisingId to bid key to bid details
    mapping(bytes32 => mapping(address => Bid)) internal listingBids;
    // track the bid latest bid id
    mapping(bytes32 => WinningBid) internal bidToListing;

    /******************************************* read state functions go here ********************************************************* */
    /**
     *
     * @dev   called by dapp or any contract to get info about a winner bid
     * @param listingId listing id
     * @return bidId bid id
     * @return bidder bidder address
 
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
            uint256 bidPrice,
            bool isPurchased,
            bool isStakeReserved
        )
    {
        bidId = bidToListing[listingId].bidId;
        bidder = bidToListing[listingId].bidder;
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
     * @return bidPrice bid price
     * @return isPurchased true if purchased
     * @return isStakeReserved true if the reserve is free
     */
    function getAuctionBidDetails(bytes32 listingId, address bidder)
        external
        view
        returns (
            bytes32 bidId,
            uint256 bidPrice,
            bool isPurchased,
            bool isStakeReserved
        )
    {
        bidId = listingBids[listingId][bidder].bidId;
        bidPrice = listingBids[listingId][bidder].bidPrice;
        isPurchased = listingBids[listingId][bidder].isPurchased;
        isStakeReserved = listingBids[listingId][bidder].isStakeReserved;
    }

    /******************************************* change state functions go here ********************************************************* */
}
