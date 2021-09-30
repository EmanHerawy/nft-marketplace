// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import './StartFiMarketPlaceAdmin.sol';
import './library/StartFiRoyalityLib.sol';
import './library/StartFiFinanceLib.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title StartFi MarketPlace
 *desc  marketplace with all functions for item selling by either ceating auction or selling with fixed prices, the contract auto transfer orginal NFT issuer's shares
 *
 */
contract StartFiMarketPlace is StartFiMarketPlaceAdmin, ReentrancyGuard {
    /******************************************* decalrations go here ********************************************************* */
    // TODO: to be updated ( using value or percentage?? develop function to ready and update the value)
    // events when auction created auction bid auction cancled auction fullfiled item listed , item purchesed , itme delisted , item delist with deduct , item  disputed , user free reserved ,
    ///
    event ListOnMarketplace(
        bytes32 listId,
        address nFTContract,
        address buyer,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 releaseTime,
        uint256 insurancAmount,
        uint256 timestamp
    );
    event DeListOffMarketplace(
        bytes32 listId,
        address nFTContract,
        address owner,
        uint256 tokenId,
        uint256 fineFees,
        uint256 releaseTime,
        uint256 timestamp
    );
    event MigrateEmergency(
        bytes32 listId,
        address nFTContract,
        address owner,
        uint256 tokenId,
        uint256 fineFees,
        uint256 releaseTime,
        uint256 timestamp
    );

    event CreateAuction(
        bytes32 listId,
        address nFTContract,
        address seller,
        uint256 tokenId,
        uint256 listingPrice,
        bool isSellForEnabled,
        uint256 sellFor,
        uint256 releaseTime,
        uint256 insurancAmount,
        uint256 timestamp
    );

    event BidOnAuction(
        bytes32 bidId,
        bytes32 listingId,
        address tokenAddress,
        address bidder,
        uint256 tokenId,
        uint256 bidPrice,
        uint256 timestamp
    );

    event FulfillBid(
        bytes32 bidId,
        bytes32 listingId,
        address tokenAddress,
        address bidder,
        uint256 tokenId,
        uint256 bidPrice,
        address issuer,
        uint256 royaltyAmount,
        uint256 fees,
        uint256 netPrice,
        uint256 timestamp
    );

    event DisputeAuction(
        bytes32 bidId,
        bytes32 listingId,
        address tokenAddress,
        address bidder,
        uint256 tokenId,
        address seller,
        uint256 insurancAmount,
        uint256 remaining,
        uint256 finefees,
        uint256 timestamp
    );

    event BuyNow(
        bytes32 listId,
        address nFTContract,
        address buyer,
        uint256 tokenId,
        uint256 sellingPrice,
        address seller,
        bool isAucton,
        address issuer,
        uint256 royaltyAmount,
        uint256 fees,
        uint256 netPrice,
        uint256 timestamp
    );
    event UserReservesFree(address user, uint256 lastReserves, uint256 newReserves, uint256 timestamp);
    event ApproveDeal(bytes32 listId, address approver, uint256 timestamp);

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _marketPlaceName,
        address _paymentContract,
        address _stakeContract,
        address _reputationContract,
        address adminWallet
    ) StartFiMarketPlaceAdmin(adminWallet, _marketPlaceName, _paymentContract, _reputationContract) {
        stakeContract = _stakeContract;
        // to be removed
        usdCap = 10000;
        stfiCap = 50000;
        stfiUsdt = 5;
    }

    /******************************************* modifiers go here ********************************************************* */

    modifier isOpenAuction(bytes32 listingId) {
        require(
            _tokenListings[listingId].releaseTime > block.timestamp &&
                _tokenListings[listingId].status == ListingStatus.onAuction,
            'Auction is ended'
        );
        _;
    }
    modifier canFulfillBid(bytes32 listingId) {
        require(
            _tokenListings[listingId].releaseTime < block.timestamp &&
                _tokenListings[listingId].status == ListingStatus.onAuction,
            'Auction is not ended or no longer on auction'
        );
        _;
    }
    modifier isOpenForSale(bytes32 listingId) {
        require(_tokenListings[listingId].status == ListingStatus.OnMarket, 'Item is not for sale');
        _;
    }
    modifier isNotZero(uint256 val) {
        require(val > 0, 'Zero Value is not allowed');
        _;
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* state functions go here ********************************************************* */

    // list
    /**
     * @dev  called by dapps to list new item
     * @param nFTContract nft contract address
     * @param tokenId token id
     * @param listingPrice min price
     * @return listId listing id
     **
      Users who want to list their NFT for sale with fixed price call this function 
    - user MUST approve contract to transfer the NFT     
    - user MUST have enough stakes used as insurance to not delist the item before the duration stated in the smart contract , if they decided to delist before that time, they lose this insurance. the required insurance amount is a percentage  based on the listing price.
    ** 
    emit : ListOnMarketplace
     */
    function listOnMarketplace(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice
    ) public whenNotPaused isNotZero(listingPrice) returns (bytes32 listId) {
        uint256 releaseTime;
        uint256 listQualifyAmount;
        if (offerTerms[_msgSender()].fee != 0) {
            releaseTime = StartFiFinanceLib._calcSum(block.timestamp, offerTerms[_msgSender()].delistAfter);
            listQualifyAmount = StartFiFinanceLib._calcFees(
                listingPrice,
                offerTerms[_msgSender()].listqualifyPercentage,
                offerTerms[_msgSender()].listqualifyPercentageBase
            );
        } else {
            releaseTime = StartFiFinanceLib._calcSum(block.timestamp, delistAfter);
            listQualifyAmount = StartFiFinanceLib._calcFees(
                listingPrice,
                listqualifyPercentage,
                listqualifyPercentageBase
            );
        }
        listId = keccak256(abi.encodePacked(nFTContract, tokenId, _msgSender(), releaseTime));
        // check that sender is qualified
        // should not be less than 1 USD
        if (listQualifyAmount < stfiUsdt) {
            listQualifyAmount = stfiUsdt;
        }
        require(
            getStakeAllowance(
                _msgSender() /*, 0*/
            ) >= listQualifyAmount,
            'Not enough reserves'
        );
        require(_isTokenApproved(nFTContract, tokenId), 'Marketplace is not allowed to transfer your token');

        // transfer token to contract

        // update reserved
        _updateUserReserves(_msgSender(), listQualifyAmount, true);
        bytes32[] storage listings = userListing[_msgSender()];
        listings.push(listId);
        userListing[_msgSender()] = listings;
        // list
        require(
            _listOnMarketPlace(
                listId,
                nFTContract,
                _msgSender(),
                tokenId,
                listingPrice,
                listQualifyAmount,
                releaseTime
            ),
            "Couldn't list the item"
        );
        emit ListOnMarketplace(
            listId,
            nFTContract,
            _msgSender(),
            tokenId,
            listingPrice,
            releaseTime,
            listQualifyAmount,
            block.timestamp
        );
        require(
            _excuteTransfer(_msgSender(), nFTContract, tokenId, address(this), address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
    }

    // list
    /**
     * @dev  called by dapps to list new item
     * @param nFTContract nft contract address
     * @param tokenId token id
     * @param listingPrice min price
      * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return listId listing id
     **
     Users who want to list their NFT for sale with fixed price call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`listOnMarketplace`] internally
     **
     */
    function listOnMarketplaceWithPremit(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 listId) {
        require(_premitNFT(nFTContract, _msgSender(), tokenId, deadline, v, r, s), 'invalid signature');
        listId = listOnMarketplace(nFTContract, tokenId, listingPrice);
    }

    // create auction
    /**
     * @dev  called by dapps to create  new auction
     * @param nFTContract nft contract address
     * @param tokenId token id
     * @param minimumBid minimum Bid price
     * @param insurancAmount  amount of token locked as qualify for any bidder wants bid
     * @param isSellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if isSellForEnabled=true
     * @param duration  when auction ends
     * @return listId listing id
     ** 
     Users who want to list their NFT as auction for bidding with/without allowing direct sale.
    - user MUST approve contract to transfer the NFT     
    - Time to live auction duration must be more than 12 hours.
    - if `sellForEnabled` is true, `sellFor` value must be more than zero
    - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI. 
    ** 
    emit : CreateAuction
     */
    function createAuction(
        address nFTContract,
        uint256 tokenId,
        uint256 minimumBid,
        uint256 insurancAmount,
        bool isSellForEnabled,
        uint256 sellFor,
        uint256 duration
    ) public whenNotPaused isNotZero(minimumBid) returns (bytes32 listId) {
        require(duration > 12 hours, 'Auction should be live for more than 12 hours');
        require(insurancAmount >= stfiUsdt, 'Invalid Auction qualify Amount');

        uint256 releaseTime = StartFiFinanceLib._calcSum(block.timestamp, duration);
        listId = keccak256(abi.encodePacked(nFTContract, tokenId, _msgSender(), releaseTime));
        if (isSellForEnabled) {
            require(sellFor >= minimumBid, 'Zero price is not allowed');
        } else {
            sellFor = 0;
        }
        // check that sender is qualified
        require(_isTokenApproved(nFTContract, tokenId), 'Marketplace is not allowed to transfer your token');

        // update reserved
        // create auction

        require(
            _creatAuction(
                listId,
                nFTContract,
                _msgSender(),
                tokenId,
                minimumBid,
                isSellForEnabled,
                sellFor,
                releaseTime,
                insurancAmount
            ),
            "Couldn't list the item"
        );
        emit CreateAuction(
            listId,
            nFTContract,
            _msgSender(),
            tokenId,
            minimumBid,
            isSellForEnabled,
            sellFor,
            releaseTime,
            insurancAmount,
            block.timestamp
        );
        // transfer token to contract

        require(
            _excuteTransfer(_msgSender(), nFTContract, tokenId, address(this), address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
    }

    /**
     * @dev  called by dapps to create  new auction
     * @param nFTContract nft contract address
     * @param tokenId token id
     * @param listingPrice min price
     * @param insurancAmount  amount of token locked as qualify for any bidder wants bid
     * @param isSellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if isSellForEnabled=true
     * @param duration  when auction ends
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return listId listing id
     ** 
     Users who want to list their NFT as auction for bidding with/without allowing direct sale call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`createAuction`] internally.
     **
     */
    function createAuctionWithPremit(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 insurancAmount,
        bool isSellForEnabled,
        uint256 sellFor,
        uint256 duration,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 listId) {
        require(_premitNFT(nFTContract, _msgSender(), tokenId, deadline, v, r, s), 'invalid signature');
        listId = createAuction(nFTContract, tokenId, listingPrice, insurancAmount, isSellForEnabled, sellFor, duration);
    }

    /**
    ** Users who interested in a certain auction, can bid on it by calling this   function.Bidder don't pay / transfer SFTI on bidding. Only when win the auction [`the auction is ended and this bidder is the last one to bid`], bidder pays by calling [`fulfillBid`] OR [`buyNowWithPremit`]
    - user MUST have enough stakes used as insurance; grantee and punishment mechanism for malicious bidder. If the bidder don't pay in the  
    - Bidders can bid as much as they wants , insurance is taken once in the first participation 
    - the bid price MUST be more than the last bid , if this is the first bid, the bid price MUST be more than or equal the minimum bid the auction creator state
    - Users CAN NOT bid on auction after auction time is over
    
    **
     * @dev called by dapps to bid on an auction
     *
     * @param listingId listing id
     * @param bidPrice price
     * @return bidId bid id
     * emit : BidOnAuction
     */
    function bid(bytes32 listingId, uint256 bidPrice)
        external
        whenNotPaused
        isOpenAuction(listingId)
        returns (bytes32 bidId)
    {
        address tokenAddress = _tokenListings[listingId].nFTContract;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        bidId = keccak256(abi.encodePacked(listingId, tokenAddress, _msgSender(), tokenId));
        // bid should be more than than the mini and more than the last bid
        address lastbidder = bidToListing[listingId].bidder;
        uint256 insurancAmount = _tokenListings[listingId].insurancAmount;
        if (lastbidder == address(0)) {
            require(
                bidPrice >= _tokenListings[listingId].listingPrice,
                'bid price must be more than or equal the minimum price'
            );
        } else {
            require(bidPrice > listingBids[listingId][lastbidder].bidPrice, 'bid price must be more than the last bid');
        }
        // if this is the bidder first bid, the price will be 0
        uint256 prevAmount = listingBids[listingId][_msgSender()].bidPrice;
        if (prevAmount == 0) {
            // check that he has reserved
            require(
                getStakeAllowance(
                    _msgSender() /*, 0*/
                ) >= insurancAmount,
                'Not enough reserves'
            );
            bytes32[] storage listings = userListing[_msgSender()];
            listings.push(listingId);
            userListing[_msgSender()] = listings;
            // update user reserves
            // reserve Zero couldn't be at any case
            require(_updateUserReserves(_msgSender(), insurancAmount, true) > 0, 'Reserve Zero is not allowed');
        }

        // bid
        require(_bid(bidId, listingId, tokenAddress, _msgSender(), tokenId, bidPrice), "Couldn't Bid");
        emit BidOnAuction(bidId, listingId, tokenAddress, _msgSender(), tokenId, bidPrice, block.timestamp);

        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }

    /**
    ** 
    After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT
    - user MUST approve contract to transfer the STFI tokens , MUST NOT be less than the bid price     
    - Winner bidder can call it within the `fulfillDuration` right after the end of the auction.
    - Winner bider can call it even after the its end as long as the auction reactor has not called dispute. the winner bidder can have chat with the seller  and if the auction creator thinks the winner bidder is not a malicious bidder,  they might agree to wait so we don't want to prevent the scenario where the can see eye to eye. At the end the auction creator wants to buy the NFT and get the price
    - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`] 
    **
    * emit : FulfillBid
     * @dev called by bidder through dapps when bidder win an auction and wants to pay to get the NFT
     *
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     */
    function fulfillBid(bytes32 listingId)
        public
        whenNotPaused
        canFulfillBid(listingId)
        returns (address _NFTContract, uint256 tokenId)
    {
        address winnerBidder = bidToListing[listingId].bidder;
        address seller = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        require(winnerBidder == _msgSender(), 'Caller is not the winner');
        // if it's new, the price will be 0
        uint256 bidPrice = listingBids[listingId][winnerBidder].bidPrice;
        if (bidPrice > stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }
        // check that contract is allowed to transfer tokens
        require(
            _getAllowance(winnerBidder) >= bidPrice,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        address issuer;
        uint256 royaltyAmount;
        uint256 fees;
        uint256 netPrice;
        if (offerTerms[seller].fee != 0) {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                bidPrice,
                offerTerms[seller].fee,
                offerTerms[seller].feeBase
            );
        } else {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                bidPrice,
                _feeFraction,
                _feeBase
            );
        }

        listingBids[listingId][_msgSender()].isPurchased = true;
        _finalizeListing(listingId, winnerBidder, ListingStatus.Sold);
        // transfer price

        require(
            _excuteTransfer(_msgSender(), _NFTContract, tokenId, seller, issuer, royaltyAmount, fees, netPrice, true),
            'StartFi: could not excute transfer'
        );

        // update user reserves
        // reserve nigative couldn't be at any case

        _updateUserReserves(winnerBidder, _tokenListings[listingId].insurancAmount, false);

        // TODO: add reputation points to both seller and buyer
        _addreputationPoints(seller, winnerBidder, bidPrice);

        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit FulfillBid(
            bidToListing[listingId].bidId,
            listingId,
            _NFTContract,
            winnerBidder,
            tokenId,
            bidPrice,
            issuer,
            royaltyAmount,
            fees,
            netPrice,
            block.timestamp
        );
    }

    function _excuteTransfer(
        address buyer,
        address _NFTContract,
        uint256 tokenId,
        address seller,
        address issuer,
        uint256 royaltyAmount,
        uint256 fees,
        uint256 netPrice,
        bool isDualDir
    ) internal nonReentrant returns (bool) {
        // transfer price

        if (isDualDir) {
            require(_safeTokenTransferFrom(buyer, _adminWallet, fees), "Couldn't transfer token as fees");
            // if the issuer is the seller , no need to send two 2 transfer transaction , let's do it 1 to reduce gas
            if (issuer == seller) {
                netPrice += royaltyAmount;
            } else if (issuer != address(0)) {
                require(_safeTokenTransferFrom(buyer, issuer, royaltyAmount), "Couldn't transfer token to issuer");
            }

            // token value could be zero ater taking the roylty share ??? need to ask?
            require(_safeTokenTransferFrom(buyer, seller, netPrice), "Couldn't transfer token to seller");
            // trnasfer token
            require(_safeNFTTransfer(_NFTContract, tokenId, address(this), buyer), "NFT token couldn't be transfered");
            return true;
        } else {
            require(_safeNFTTransfer(_NFTContract, tokenId, buyer, seller), "NFT token couldn't be transfered");
            return true;
        }
    }

    /**
    **After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT, they call this function without sending prior transaction to `approve` the marketplace to transfer STFI. This function call`permit` [`eip-2612`] then call [`fulfillBid`] internally.
    ** 
     * @dev called by bidder through dapps when bidder win an auction and wants to pay to get the NFT
     *
     * @param listingId listing id
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
       * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id

     */
    function fulfillBidWithPremit(
        bytes32 listingId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address _NFTContract, uint256 tokenId) {
        require(
            _permit(_msgSender(), listingBids[listingId][_msgSender()].bidPrice, deadline, v, r, s),
            'StartFi: Invalid signature'
        );

        return fulfillBid(listingId);
    }

    // delist

    /**
    ** Users who no longer want to keep their NFT in our marketplace can easly call this function to get their NFT back. Unsuccessful auction creators need to call it as well to get their nft back with no cost while the item added via [`listOnMarketplace`] or [`listOnMarketplaceWithPremit`]  might lose the insurance amount if they decided to delist the items before the greed time stated in the contract `delistAfter`
    - Only buyers can delist their own items 
    - Auction items can't delisted until the auction ended
    **
     * @dev called by seller through dapps when s/he wants to remove this token from the marketplace
     * @notice auction can't be canceled , if seller delist time on sale on maretplace before time to delist, he will pay a fine
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     * emit DeListOffMarketplace
     */
    function deList(bytes32 listingId) external whenNotPaused returns (address _NFTContract, uint256 tokenId) {
        ListingStatus status = _tokenListings[listingId].status;
        address buyer = _tokenListings[listingId].buyer;
        address _owner = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        uint256 releaseTime = _tokenListings[listingId].releaseTime;
        tokenId = _tokenListings[listingId].tokenId;
        require(_owner == _msgSender(), 'Caller is not the owner');
        require(buyer == address(0), 'Already bought token');
        uint256 timeToDelistAuction = StartFiFinanceLib._calcSum(releaseTime, 3 days);

        require(
            status == ListingStatus.OnMarket || status == ListingStatus.onAuction,
            'Already bought or canceled token'
        );
        require(
            (timeToDelistAuction <= block.timestamp && status == ListingStatus.onAuction) ||
                (status == ListingStatus.OnMarket),
            "Can't delist"
        );

        // if realse time < now , pay
        if (status != ListingStatus.onAuction) {
            if (releaseTime > block.timestamp) {
                // if it's not auction ? pay,

                //TODO: deduct the fine from his stake contract

                require(
                    _deduct(_owner, _adminWallet, _tokenListings[listingId].insurancAmount),
                    "couldn't deduct the fine"
                );
            }
            // update user reserves
            // reserve nigative couldn't be at any case

            _updateUserReserves(_msgSender(), _tokenListings[listingId].insurancAmount, false);
        }

        // finish listing
        _finalizeListing(listingId, address(0), ListingStatus.Canceled);
        emit DeListOffMarketplace(
            listingId,
            _NFTContract,
            _owner,
            tokenId,
            _tokenListings[listingId].insurancAmount,
            releaseTime,
            block.timestamp
        );
        // trnasfer token

        require(
            _excuteTransfer(address(this), _NFTContract, tokenId, _owner, address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
    }

    // buynow
    /**
    **  Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can call this function.
    - User MUST approve contract to transfer the STFI token , MUST NOT be less than the price.
   - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`]
   **
     * @dev called by buyer through dapps when s/he wants to buy a gevin NFT  token from the marketplace
     * @notice  if auction, the seller must enabe forSale. prices should be more than or equal the listing price
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     * emit : BuyNow
     */
    function buyNow(bytes32 listingId) public whenNotPaused returns (address _NFTContract, uint256 tokenId) {
        bool isSellForEnabled = _tokenListings[listingId].isSellForEnabled;

        uint256 price;
        if (_tokenListings[listingId].status == ListingStatus.OnMarket) {
            price = _tokenListings[listingId].listingPrice;
        } else if (_tokenListings[listingId].status == ListingStatus.onAuction) {
            require(
                isSellForEnabled == true && _tokenListings[listingId].releaseTime > block.timestamp,
                'Token is not for sale'
            );
            price = _tokenListings[listingId].sellFor;
        }
        address seller = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        require(price > 0, 'StartfiMarketplce: Invalid price or Token is not for sale');
        if (price > stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }

        // check that contract is allowed to transfer tokens
        require(
            _getAllowance(_msgSender()) >= price,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        address issuer;
        uint256 royaltyAmount;
        uint256 fees;
        uint256 netPrice;
        uint256 ListingQualAmount = _tokenListings[listingId].insurancAmount;
        // transfer price
        if (offerTerms[seller].fee != 0) {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                price,
                offerTerms[seller].fee,
                offerTerms[seller].feeBase
            );
        } else {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                price,
                _feeFraction,
                _feeBase
            );
        }

        // free reserves for seller
        if (_tokenListings[listingId].status == ListingStatus.OnMarket) {
            _updateUserReserves(seller, ListingQualAmount, false);
        }

        // finish listing
        _finalizeListing(listingId, _msgSender(), ListingStatus.Sold);
        // TODO: add reputation points to both seller and buyer
        _addreputationPoints(seller, _msgSender(), price);
        emit BuyNow(
            listingId,
            _NFTContract,
            _msgSender(),
            tokenId,
            price,
            seller,
            isSellForEnabled,
            issuer,
            royaltyAmount,
            fees,
            netPrice,
            block.timestamp
        );
        require(
            _excuteTransfer(_msgSender(), _NFTContract, tokenId, seller, issuer, royaltyAmount, fees, netPrice, true),
            'StartFi: could not excute transfer'
        );
    }

    //
    /**
    ** 
    Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can this call this function without sending prior transaction to `approve` the marketplace to transfer STFI tokens. This function call`permit` [`eip-2612`] then call [`buyNow`] internally.
    **
     * @dev called by buyer through dapps when s/he wants to buy a gevin NFT  token from the marketplace
     * @notice  if auction, the seller must enabe forSale. prices should be more than or equal the listing price
     * @param listingId listing id
     * @param price gevin price
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
 
     */
    function buyNowWithPremit(
        bytes32 listingId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(_permit(_msgSender(), price, deadline, v, r, s), 'StartFi: Invalid signature');
        buyNow(listingId);
    }

    /**
    ** 
    If the winning bidder didn't pay within the time range stated in te contract `fulfillDuration`, Auction creator calls this function to get the nft back and punish the malicious bidder by taking the insurance (50% goes to the auction staking balance, 50% goes to the platform)
    - Current time  MUST be more than or equal the `disputeTime` for this auction     
    - Only auction Creator can dispute.
    - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, and the auction is approved , auction creator can dispute, if it's not approved yet, auction creator can not.
- [`buyNow`]: Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can call this function.
    - User MUST approve contract to transfer the STFI token , MUST NOT be less than the price.
   - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`]
   **
     * @dev called by seller through dapps when his/her auction is  not fulfilled after 3 days
     *  @notice  after auction with winner bid . bidder didn't call fullfile within 3 days of auction closing  auction owner can call dispute to delist and punish the spam winner bidder fine is share between the plateform and the auction owner
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     * emit : DisputeAuction
     */
    function disputeAuction(bytes32 listingId) external whenNotPaused returns (address _NFTContract, uint256 tokenId) {
        address winnerBidder = bidToListing[listingId].bidder;
        address seller = _tokenListings[listingId].seller;
        require(seller == _msgSender(), 'Only Seller can dispute');
        _NFTContract = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        uint256 insurancAmount = _tokenListings[listingId].insurancAmount;
        uint256 timeToDispute = _tokenListings[listingId].disputeTime;
        require(winnerBidder != address(0), 'Marketplace: Auction has no bids');
        require(timeToDispute <= block.timestamp, 'Marketplace: Can not dispute before time');
        require(_tokenListings[listingId].status == ListingStatus.onAuction, 'Marketplace: Item is not on Auction');
        if (listingBids[listingId][winnerBidder].bidPrice > stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }
        //50% goes to the platform
        (uint256 fineAmount, uint256 remaining) = StartFiFinanceLib._calcBidDisputeFees(insurancAmount);
        // call staking contract to deduct
        require(
            _deduct(winnerBidder, _adminWallet, fineAmount),
            "Marketplace: couldn't deduct the fine for the admin wallet"
        );
        require(_deduct(winnerBidder, seller, remaining), "Marketplace: couldn't deduct the fine for the admin wallet");

        _updateUserReserves(winnerBidder, insurancAmount, false);
        // finish listing
        _finalizeListing(listingId, address(0), ListingStatus.Canceled);
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit DisputeAuction(
            bidToListing[listingId].bidId,
            listingId,
            _NFTContract,
            winnerBidder,
            tokenId,
            seller,
            insurancAmount,
            remaining,
            fineAmount,
            block.timestamp
        );
        // transfer token
        require(
            _excuteTransfer(address(this), _NFTContract, tokenId, seller, address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
    }

    /**
    ** users need to stake STFI to list or bid in the marketplace , these tokens needs to set free if the auction is no longer active and user can use these stakes to bid , list or even to withdraw tokens thus, function to free tokens reserved to items of market 
 *  in order to keep track of the on hold stakes.  
 * we store user on-hold stakes in a map `userReserves` 
 * to get user on-hold reserves call  getUserReserved on marketplace
 * to get the number of stakes that not on hold, call  userReserves on marketplace , this function subtract the user stakes in staking contract from the on-hold stakes on marketplace
*This function is greedy, called by user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
   - Only users can free their own reserves 
   ** 
    * @dev called by user through dapps when his/her wants to free his reserved tokens which are no longer in active auction .
    *  @notice this function is greedy, called by user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
  
    * @return curentReserves user reserves after freeing the unused reservd
    * emit : UserReservesFree
     */

    function freeReserves() external returns (uint256 curentReserves) {
        // TODo: Check allternative for gas consumptions
        // iterate over the listng key map
        // if it's sold, canceled,  free if he is participating on this listing
        uint256 lastReserves = userReserves[_msgSender()];
        bytes32[] memory listings = userListing[_msgSender()];
        delete userListing[_msgSender()];
        bytes32[] storage newListings = userListing[_msgSender()];

        // loop
        for (uint256 index = 0; index < listings.length; index++) {
            /**
             * we want to free stakes bidders do in auctions with the following scenarios
             * - bidder is not the winner and the auction is ended ( bought, fulfilled , dispute) , free
             *- auction is finished, is not the winner bidder and winner bidder and auction creator have not fulfilled or disputed , free
             */
            if (_tokenListings[listings[index]].status == ListingStatus.onAuction) {
                if (
                    _tokenListings[listings[index]].disputeTime < block.timestamp &&
                    bidToListing[listings[index]].bidder != _msgSender()
                ) {
                    // free
                } else {
                    newListings.push(listings[index]);
                    curentReserves = _tokenListings[listings[index]].insurancAmount;
                }
            } else if (_tokenListings[listings[index]].status == ListingStatus.OnMarket) {
                newListings.push(listings[index]);
                uint256 listQualifyAmount = _tokenListings[listings[index]].insurancAmount;

                curentReserves += listQualifyAmount;
            }
        }
        userListing[_msgSender()] = newListings;
        require(_setUserReserves(_msgSender(), curentReserves), 'set reserve faild');
        emit UserReservesFree(_msgSender(), lastReserves, curentReserves, block.timestamp);
    }

    /**
    *STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and any purchase transaction with price exceed the cap can't be proceed unless this deal is approved by Startfi by calling this function
- called only by account in owner role
     * @dev only called by `owner` to approve listing that exceeded cap after doing the KYC
     *@param listingId listing Id
     * emit ApproveDeal
     */
    function approveDeal(bytes32 listingId) external onlyOwner whenNotPaused {
        require(
            _tokenListings[listingId].status == ListingStatus.onAuction ||
                _tokenListings[listingId].status == ListingStatus.OnMarket,
            'StartFiMarketplace: Invalid ITem'
        );
        /**
       we have the following scenario : 
       * auction bid get higher than the cap , and needs to get approved 
       * kyc process for anyreason takes some longer time that might exceed the time to dispute 
       * malicious auction creator call diputeAuction and winner bider loses money 
       * to protect we put condition on dispute to check if the bid price exceed cap and the deal is approved in order to proceed because at this case this is malicious bidder
       * second condition is in deal approval, if we have approved the deal before time to realse ( we are monitoring the marketplace when the auction bids exceed the cap , we can  ) 
       */
        if (_tokenListings[listingId].status == ListingStatus.onAuction) {
            if (_tokenListings[listingId].releaseTime < block.timestamp) {
                _tokenListings[listingId].disputeTime = StartFiFinanceLib._calcSum(block.timestamp, fulfillDuration);
            }
        }
        kycedDeals[listingId] = true;
        emit ApproveDeal(listingId, _msgSender(), block.timestamp);
    }

    /**
     *  @dev only called by `owner` to update the cap
     * @param _usdCap  the new fees value to be stored
     */
    function setUsdCap(uint256 _usdCap) external onlyOwner whenPaused {
        _setCap(_usdCap);
    }

    /**
     *  @dev only called by  `priceFeeds` to update the STFI/usdt price
     * @param _stfiPrice  the new stfi price per usdt
     */
    function setPrice(uint256 _stfiPrice) external {
        require(hasRole(PRICE_FEEDER_ROLE, _msgSender()), 'StartFiMarketPlace: UnAuthorized caller');
        // set
        stfiUsdt = _stfiPrice;
        stfiCap = _stfiPrice * usdCap;
    }

    /** **************************Emergency Zone ********************/

    /**
    **
    Only when contract is paused, users can safely delist their token with no cost. Startfi team might have to pause the contract to make any update on the protocol terms or in emergency if high risk vulnerability is discovered to protect the users.    
   - Only buyers can delist their own items 
   **
     * @dev called by seller through dapps when s/he wants to remove this token from the marketplace
     * @notice called only when puased , let user to migrate for free if they don't agree on our new terms
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     * emit : MigrateEmergency
     */
    function migrateEmergency(bytes32 listingId) external whenPaused returns (address _NFTContract, uint256 tokenId) {
        ListingStatus status = _tokenListings[listingId].status;
        address buyer = _tokenListings[listingId].buyer;
        address _owner = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        uint256 releaseTime = _tokenListings[listingId].releaseTime;
        tokenId = _tokenListings[listingId].tokenId;
        require(_owner == _msgSender(), 'Caller is not the owner');
        require(buyer == address(0), 'Already bought token');
        require(
            status == ListingStatus.OnMarket || status == ListingStatus.onAuction,
            'Already bought or canceled token'
        );

        // if realse time < now , pay
        if (status == ListingStatus.OnMarket) {
            // update user reserves
            // reserve nigative couldn't be at any case

            _updateUserReserves(_msgSender(), _tokenListings[listingId].insurancAmount, false);
        }

        // finish listing
        _finalizeListing(listingId, address(0), ListingStatus.Canceled);
        emit MigrateEmergency(
            listingId,
            _NFTContract,
            _owner,
            tokenId,
            _tokenListings[listingId].insurancAmount,
            releaseTime,
            block.timestamp
        );
        require(
            _excuteTransfer(address(this), _NFTContract, tokenId, _owner, address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
    }
}
