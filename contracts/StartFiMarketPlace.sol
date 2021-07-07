// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
import "./StartfiMarketPlaceFinance.sol";
import "./MarketPlaceListing.sol";
import "./MarketPlaceBid.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author Eman Herawy, StartFi Team
 *@title StartFi MarketPlace
 *desc  marketplace with all functions for item selling by either ceating auction or selling with fixed prices, the contract auto transfer orginal NFT issuer's shares   
 * 
 */
contract StartFiMarketPlace is  Ownable ,Pausable, MarketPlaceListing, MarketPlaceBid,StartfiMarketPlaceFinance {
  
 /******************************************* decalrations go here ********************************************************* */
 // TODO: to be updated ( using value or percentage?? develop function to ready and update the value)
uint256 minQualifyAmount =10;
// events when auction created auction bid auction cancled auction fullfiled item listed , item purchesed , itme delisted , item delist with deduct , item  disputed , user free reserved , 
///
event ListOnMarketplace(  bytes32 listId,address nftAddress,address buyer,uint256 tokenId,uint256 listingPrice,uint256 releaseTime,uint256 qualifyAmount,   uint256 timestamp );
event DeListOffMarketplace(  bytes32 listId,address nftAddress,address buyer,uint256 tokenId,uint256 fineFees, uint256 remaining,uint256 releaseTime,  uint256 timestamp );

event CreateAuction(   bytes32 listId,address nftAddress,address buyer,uint256 tokenId,uint256 listingPrice,bool sellForEnabled,uint256 sellFor,uint256 releaseTime,uint256 qualifyAmount,uint256 timestamp );

event BidOnAuction(bytes32 bidId , bytes32 listingId, address tokenAddress,address bidder, uint256 tokenId, uint256 bidPrice,uint256 timestamp );
 
 event FullfillBid(bytes32 bidId , bytes32 listingId, address tokenAddress,address bidder, uint256 tokenId, uint256 bidPrice,address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice ,uint256 timestamp );

 event DisputeAuction(bytes32 bidId , bytes32 listingId, address tokenAddress,address bidder, uint256 tokenId  ,address buyer,uint256 qualifyAmount, uint256 remaining,uint256 finefees,uint256 timestamp );

 event BuyNow(  bytes32 listId,address nftAddress,address buyer,uint256 tokenId,uint256 sellingPrice,address seller,bool isAucton,address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice,   uint256 timestamp );
event UserReservesFree(address user, uint256 lastReserves,uint256 newReserves,uint256 timestamp );




 /******************************************* constructor goes here ********************************************************* */

    constructor(
          string memory _marketPlaceName,
          address _paymentTokesnAddress,
          address _stakeContract
    )   StartfiMarketPlaceFinance(_marketPlaceName,_paymentTokesnAddress){
       stakeContract=_stakeContract;
    }

  /******************************************* modifiers go here ********************************************************* */

    modifier isOpenAuction(bytes32 listingId) {
        require(  _tokenListings[listingId].releaseTime> block.timestamp && _tokenListings[listingId].status!=ListingStatus.onAuction,"Auction is ended");
        _;
    }
    modifier canFullfillBid(bytes32 listingId) {
        require(  _tokenListings[listingId].releaseTime< block.timestamp && _tokenListings[listingId].status!=ListingStatus.onAuction,"Auction is ended");
        _;
    }
    modifier isOpenForSale(bytes32 listingId) {
        require(_tokenListings[listingId].status==ListingStatus.OnMarket,"Item is not for sale");
        _;
    }
modifier isNotZero(uint256 val) {
    require(val>0,"Zero Value is not allowed");
    _;
}

  /******************************************* read state functions go here ********************************************************* */

  /******************************************* state functions go here ********************************************************* */

// list
     /**
    * @dev  called by dapps to list new item 
    * @param nftAddress nft contract address
    * @param tokenId token id 
    * @param listingPrice min price 
     * @return listId listing id
     */
    function listOnMarketplace( address nftAddress,
          uint256 tokenId,
            uint256 listingPrice ) external isNotZero(listingPrice) returns (bytes32 listId) {
            uint256 releaseTime = _calcSum(block.timestamp,delistAfter);
            listId = keccak256(abi.encodePacked(nftAddress,tokenId,_msgSender(),releaseTime));
            // calc qualified ammount
            uint256 listQualifyAmount =_getListingQualAmount(listingPrice);

          // check that sender is qualified 
          require(_getStakeAllowance(_msgSender()/*, 0*/)>= listQualifyAmount,"Not enough reserves");
          require( _isTokenApproved(nftAddress,  tokenId) ,"Marketplace is not allowed to transfer your token");

            // transfer token to contract 
          require( _safeNFTTransfer(nftAddress,tokenId,_msgSender(),address(this)),"NFT token couldn't be transfered");

          // update reserved
            _updateUserReserves(_msgSender() ,listQualifyAmount,true);
            bytes32  [] storage listings = userListing[_msgSender()];
            listings.push(listId);
            userListing[_msgSender()]=listings;
          // list 
          require(_listOnMarketPlace( listId,nftAddress,_msgSender(),tokenId,listingPrice,releaseTime) ,"Couldn't list the item");
          emit ListOnMarketplace( listId,nftAddress,_msgSender(),tokenId,listingPrice,releaseTime,listQualifyAmount, block.timestamp);
        
    }
// create auction
  /**
    * @dev  called by dapps to create  new auction 
    * @param nftAddress nft contract address
    * @param tokenId token id 
    * @param listingPrice min price 
    * @param qualifyAmount  amount of token locked as qualify for any bidder wants bid 
    * @param sellForEnabled true if auction enable direct selling
    * @param sellFor  price  to sell with if sellForEnabled=true
    * @param duration  when auction ends
    * @return listId listing id
     */
    function createAuction( address nftAddress,
          uint256 tokenId,
            uint256 listingPrice,
            uint256 qualifyAmount,
            bool sellForEnabled,
            uint256 sellFor,
            uint256 duration
            ) external isNotZero(listingPrice) returns (bytes32 listId) {
              require(duration>12 hours,"Auction should be live for more than 12 hours");
              require(qualifyAmount>=minQualifyAmount,"Invalid Auction qualify Amount");
            uint256 releaseTime = _calcSum(block.timestamp,duration);
            listId = keccak256(abi.encodePacked(nftAddress,tokenId,_msgSender(),releaseTime));
            if(sellForEnabled){
              require(sellFor>0,"Zero price is not allowed");
            }
          // check that sender is qualified 
            require( _isTokenApproved(nftAddress,  tokenId) ,"Marketplace is not allowed to transfer your token");

            // transfer token to contract 
          require( _safeNFTTransfer(nftAddress,tokenId,_msgSender(),address(this)),"NFT token couldn't be transfered");

            // update reserved
            // create auction

          require(_creatAuction( listId,nftAddress,_msgSender(),tokenId,listingPrice,   sellForEnabled,sellFor,releaseTime,qualifyAmount) ,"Couldn't list the item");
           emit CreateAuction( listId,nftAddress,_msgSender(),tokenId,listingPrice,   sellForEnabled,sellFor,releaseTime,qualifyAmount,block.timestamp); 
        
    }
      /**
    * @dev called by dapps to bid on an auction
    * 
    * @param listingId listing id 
    * @param tokenAddress nft contract address
    * @param tokenId token id 
    * @param bidPrice price 
    * @return bidId bid id
     */
    function bid(bytes32 listingId, address tokenAddress, uint256 tokenId, uint256 bidPrice) 
        external isOpenAuction(listingId) returns (bytes32 bidId){
         bidId = keccak256(abi.encodePacked(listingId,tokenAddress,_msgSender(),tokenId));
         // bid should be more than than the mini and more than the last bid
        address lastbidder= bidToListing[listingId].bidder;
            uint256 qualifyAmount =  _tokenListings[listingId].qualifyAmount;
         if(lastbidder==address(0)){
             require(bidPrice>= _tokenListings[listingId].listingPrice,"bid price must be more than or equal the minimum price");

         }else{
            require(bidPrice>listingBids[listingId][lastbidder].bidPrice,"bid price must be more than the last bid");

                          
         }
         // if this is the bidder first bid, the price will be 0 
       uint256 prevAmount= listingBids[listingId][_msgSender()].bidPrice;
       if(prevAmount==0){
                  // check that he has reserved
         require(_getStakeAllowance(_msgSender()/*, 0*/)>= qualifyAmount,"Not enough reserves");
          bytes32 [] storage listings = userListing[_msgSender()];
            listings.push(listingId);
            userListing[_msgSender()]=listings;
         // update user reserves
         // reserve Zero couldn't be at any case
        require( _updateUserReserves(_msgSender() ,qualifyAmount,true)>0,"Reserve Zero is not allowed");
       }
       
         // bid 
         require(_bid( bidId, listingId,  tokenAddress, _msgSender(),   tokenId,   bidPrice),"Couldn't Bid");
         emit BidOnAuction( bidId, listingId,  tokenAddress, _msgSender(),   tokenId,   bidPrice,block.timestamp);
     
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }
    /**
    * @dev called by bidder through dapps when bidder win an auction and wants to pay to get the NFT 
    * 
    * @param listingId listing id 
    * @return contractAddress nft contract address
    * @return tokenId token id 
     */
    function fullfillBid(bytes32 listingId) 
        external canFullfillBid(listingId) returns (address contractAddress,uint256 tokenId){
         address winnerBidder= bidToListing[listingId].bidder;
         address buyer= _tokenListings[listingId].buyer;
           contractAddress= _tokenListings[listingId]. nftAddress;
           tokenId= _tokenListings[listingId]. tokenId;
        require(winnerBidder==_msgSender(),"Caller is not the winner");
         // if it's new, the price will be 0 
        uint256 bidPrice= listingBids[listingId][winnerBidder].bidPrice;
         // check that contract is allowed to transfer tokens 
         require(_getAllowance(winnerBidder)>= bidPrice,"Marketplace is not allowed to withdraw the required amount of tokens");
        // transfer price 
    
        (address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice) = _getListingFinancialInfo( contractAddress,tokenId, bidPrice) ;
      
       require(_safeTokenTransferFrom(owner(),buyer, fees),"Couldn't transfer token as fees");
       if(issuer!=address(0)){
       require(_safeTokenTransferFrom(issuer,buyer, royaltyAmount),"Couldn't transfer token to issuer");
       }

        // token value could be zero ater taking the roylty share ??? need to ask?
        require(_safeTokenTransferFrom(winnerBidder,buyer, netPrice),"Couldn't transfer token to buyer");
          // trnasfer token
        require( _safeNFTTransfer(contractAddress,tokenId,address(this), winnerBidder),"NFT token couldn't be transfered");
         // update user reserves
         // reserve nigative couldn't be at any case
        require( _updateUserReserves(winnerBidder,_tokenListings[listingId].qualifyAmount,false)>=0,"negative reserve is not allowed");
        listingBids[listingId][_msgSender()].isPurchased=true;
        // TODO: add reputation points to both seller and buyer

        // finish listing 
        _finalizeListing(listingId,winnerBidder, ListingStatus.Sold);
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit FullfillBid(  bidToListing[listingId].bidId ,   listingId,   contractAddress, winnerBidder,  tokenId,  bidPrice,  issuer,  royaltyAmount,   fees,   netPrice ,block.timestamp );
    }
// delist
    /**
    * @dev called by seller through dapps when s/he wants to remove this token from the marketplace   
    * @notice auction can't be canceled , if seller delist time on sale on maretplace before time to delist, he will pay a fine
    * @param listingId listing id 
    * @return contractAddress nft contract address
    * @return tokenId token id 
     */
    function deList(bytes32 listingId) 
        external  returns ( address contractAddress,uint256 tokenId){
         ListingStatus status= _tokenListings[listingId].status;
         address owner= _tokenListings[listingId].buyer;
         address seller= _tokenListings[listingId].seller;
         contractAddress= _tokenListings[listingId]. nftAddress;
         uint256 releaseTime= _tokenListings[listingId]. releaseTime;
         uint256 listingPrice= _tokenListings[listingId]. listingPrice;
         tokenId= _tokenListings[listingId]. tokenId;
         require(owner==_msgSender(),"Caller is not the owner");
         require(seller==address(0),"Already bought token");
      uint256 timeToDelistAuction= _calcSum( releaseTime,3 days);

        // require(status==ListingStatus.OnMarket || status==ListingStatus.onAuction,"Already bought or canceled token");
        require((timeToDelistAuction<=block.timestamp && status==ListingStatus.onAuction)|| (status==ListingStatus.OnMarket),"Can't delist");
        uint256 fineAmount ;
         uint256 remaining;
        // if realse time < now , pay 

        if(releaseTime<block.timestamp){
          // if it's not auction ? pay, 
         ( fineAmount ,  remaining)= _getDeListingQualAmount(listingPrice);
              //TODO: deduct the fine from his stake contract 
            
               require(_deduct(owner,getAdminWallet(), fineAmount),"couldn't deduct the fine");
        }else{
       remaining=  _getListingQualAmount( listingPrice);
        }

        // trnasfer token
        require( _safeNFTTransfer(contractAddress,tokenId,address(this), owner),"NFT token couldn't be transfered");
         // update user reserves
         // reserve nigative couldn't be at any case
        require( _updateUserReserves(_msgSender() ,remaining,false)>=0,"negative reserve is not allowed");
        // finish listing 
         _finalizeListing(listingId,address(0),ListingStatus.Canceled);
         emit DeListOffMarketplace(listingId,  contractAddress,  owner,  tokenId,  fineAmount ,  remaining,  releaseTime,  block.timestamp );
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }


// buynow
 /**
    * @dev called by buyer through dapps when s/he wants to buy a gevin NFT  token from the marketplace   
    * @notice  if auction, the seller must enabe forSale. prices should be more than or equal the listing price
    * @param listingId listing id 
    * @param price gevin price
    * @return contractAddress nft contract address
    * @return tokenId token id 
     */
    function buyNow(bytes32 listingId, uint256 price) 
        external  returns (address contractAddress,uint256 tokenId){
          bool sellForEnabled= _tokenListings[listingId].sellForEnabled;
         address buyer= _tokenListings[listingId].buyer;
           contractAddress= _tokenListings[listingId]. nftAddress;
           tokenId= _tokenListings[listingId]. tokenId;
         require(price>=_tokenListings[listingId]. listingPrice,"Invalid price");
        require(_tokenListings[listingId].status==ListingStatus.OnMarket || (_tokenListings[listingId].status==ListingStatus.onAuction && sellForEnabled==true && _tokenListings[listingId].releaseTime> block.timestamp ),"Token isnot for sale ");
         // check that contract is allowed to transfer tokens 
         require(_getAllowance(_msgSender())>= price,"Marketplace is not allowed to withdraw the required amount of tokens");
        // transfer price 
    
        (address issuer,uint256 royaltyAmount, uint256 fees, uint256 netPrice) = _getListingFinancialInfo( contractAddress,tokenId, price) ;
      
       require(_safeTokenTransferFrom(owner(),buyer, fees),"Couldn't transfer token as fees");
       if(issuer!=address(0)){
       require(_safeTokenTransferFrom(issuer,buyer, royaltyAmount),"Couldn't transfer token to issuer");
       }

        // token value could be zero ater taking the roylty share ??? need to ask?
        require(_safeTokenTransferFrom(_msgSender(),buyer, netPrice),"Couldn't transfer token to buyer");
          // trnasfer token
        require( _safeNFTTransfer(contractAddress,tokenId,address(this), _msgSender()),"NFT token couldn't be transfered");
           uint256 ListingQualAmount =  _getListingQualAmount( _tokenListings[listingId]. listingPrice);

            require( _updateUserReserves(buyer ,ListingQualAmount,false)>=0,"negative reserve is not allowed");

        // finish listing 
        _finalizeListing(listingId,_msgSender(), ListingStatus.Sold);
        // TODO: add reputation points to both seller and buyer
      emit BuyNow  (listingId,contractAddress,  buyer,  tokenId,  price,_msgSender(),sellForEnabled,  issuer,  royaltyAmount,   fees,   netPrice,   block. timestamp );
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }

 /**
    * @dev called by seller through dapps when his/her auction is  not fullfilled after 3 days
    *  @notice  after auction with winner bid . bidder didn't call fullfile within 3 days of auction closing  auction owner can call dispute to delist and punish the spam winner bidder fine is share between the plateform and the auction owner
    * @param listingId listing id 
    * @return contractAddress nft contract address
    * @return tokenId token id 
     */
    function disputeAuction(bytes32 listingId) 
        external  returns (address contractAddress,uint256 tokenId){
         address winnerBidder= bidToListing[listingId].bidder;
         address buyer= _tokenListings[listingId].buyer;
           contractAddress= _tokenListings[listingId]. nftAddress;
           tokenId= _tokenListings[listingId]. tokenId;
           uint256 qualifyAmount =  _tokenListings[listingId].qualifyAmount;
            uint256 timeToDispute= _calcSum(_tokenListings[listingId]. releaseTime,3 days);
         require(winnerBidder!=address(0) && timeToDispute>=block.timestamp,"No bids or still running auction");
       require(buyer==_msgSender(),"Caller is not the owner");
      require(!listingBids[listingId][winnerBidder].isPurchased,"Already purchased");
          // call staking contract to deduct 
        (uint256 fineAmount ,uint256  remaining)= _calcBidDisputeFees(qualifyAmount);
        require(_deduct(winnerBidder,getAdminWallet(), fineAmount),"couldn't deduct the fine for the admin wallet");
        require(_deduct(winnerBidder, buyer, remaining),"couldn't deduct the fine for the admin wallet");
           // trnasfer token
        require( _safeNFTTransfer(contractAddress,tokenId,address(this),buyer),"NFT token couldn't be transfered");
            require( _updateUserReserves(winnerBidder ,qualifyAmount,false)>=0,"negative reserve is not allowed");

        // finish listing 
         _finalizeListing(listingId,address(0),ListingStatus.Canceled);
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
         emit DisputeAuction(  bidToListing[listingId].bidId ,   listingId,  contractAddress ,winnerBidder,   tokenId,    buyer,  qualifyAmount, remaining,  fineAmount, block. timestamp );

    }

     /**
    * @dev called by user through dapps when his/her wants to free his reserved tokens which are no longer in active auction or listing
    *  @notice this function is greedy, called by user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
  
    * @return curentReserves user reserves after freeing the unused reservd

     */

    function freeReserves() external returns (uint256 curentReserves) {
      // TODo: Check allternative for gas consumptions
      // iterate over the listng key map 
      // if it's sold, canceled,  free if he is participating on this listing
            uint256 lastReserves =userReserves[_msgSender()];
            bytes32 [] memory listings = userListing[_msgSender()];
            delete userListing[_msgSender()];
            bytes32 [] storage newListings = userListing[_msgSender()]  ;
             

            // loop
        for (uint256 index = 0; index < listings.length; index++) {
        if( _tokenListings[ listings[index]].status==ListingStatus.onAuction){
              newListings.push(listings[index]);
              curentReserves = _calcSum(curentReserves,_tokenListings[ listings[index]].qualifyAmount);

        }else if ( _tokenListings[ listings[index]].status==ListingStatus.OnMarket){
                        newListings.push(listings[index]);
                      uint256 listQualifyAmount =_getListingQualAmount(_tokenListings[ listings[index]].listingPrice);

                     curentReserves = _calcSum(curentReserves,listQualifyAmount);

        }
        }       
      userListing[_msgSender()]=newListings;
      require( _setUserReserves(_msgSender() ,curentReserves),"set reserve faild");
      emit UserReservesFree(_msgSender(),  lastReserves,curentReserves,block. timestamp );

    }

    // ubnormal isssue with calling owner() in deList unction , we have implemented this func as a workaround 
    function getAdminWallet() view private returns (address) {
      return owner() ;
    }
}