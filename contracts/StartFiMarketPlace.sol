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
        uint256 qualifyAmount,
        uint256 timestamp
    );
    event DeListOffMarketplace(
        bytes32 listId,
        address nFTContract,
        address owner,
        uint256 tokenId,
        uint256 fineFees,
        uint256 remaining,
        uint256 releaseTime,
        uint256 timestamp
    );

    event CreateAuction(
        bytes32 listId,
        address nFTContract,
        address seller,
        uint256 tokenId,
        uint256 listingPrice,
        bool sellForEnabled,
        uint256 sellFor,
        uint256 releaseTime,
        uint256 qualifyAmount,
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

    event FullfillBid(
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
        uint256 qualifyAmount,
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

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _marketPlaceName,
        address _paymentContract,
        address _stakeContract,
        address _reputationContract,
        address adminWallet
    ) StartFiMarketPlaceAdmin(adminWallet, _marketPlaceName, _paymentContract, _reputationContract) {
        stakeContract = _stakeContract;
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
    modifier canFullfillBid(bytes32 listingId) {
        require(
            _tokenListings[listingId].releaseTime < block.timestamp &&
                _tokenListings[listingId].status == ListingStatus.onAuction,
            'Auction is ended'
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
     */
    function listOnMarketplace(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice
    ) public isNotZero(listingPrice) returns (bytes32 listId) {
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
            _getStakeAllowance(
                _msgSender() /*, 0*/
            ) >= listQualifyAmount,
            'Not enough reserves'
        );
        require(_isTokenApproved(nFTContract, tokenId), 'Marketplace is not allowed to transfer your token');

        // transfer token to contract

        require(
            _excuteTransfer(_msgSender(), nFTContract, tokenId, address(this), address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );

        // update reserved
        _updateUserReserves(_msgSender(), listQualifyAmount, true);
        bytes32[] storage listings = userListing[_msgSender()];
        listings.push(listId);
        userListing[_msgSender()] = listings;
        // list
        require(
            _listOnMarketPlace(listId, nFTContract, _msgSender(), tokenId, listingPrice, releaseTime),
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
     * @param listingPrice min price
     * @param qualifyAmount  amount of token locked as qualify for any bidder wants bid
     * @param sellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if sellForEnabled=true
     * @param duration  when auction ends
     * @return listId listing id
     */
    function createAuction(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 qualifyAmount,
        bool sellForEnabled,
        uint256 sellFor,
        uint256 duration
    ) public isNotZero(listingPrice) returns (bytes32 listId) {
        require(duration > 12 hours, 'Auction should be live for more than 12 hours');
        require(qualifyAmount >= stfiUsdt, 'Invalid Auction qualify Amount');

        uint256 releaseTime = StartFiFinanceLib._calcSum(block.timestamp, duration);
        listId = keccak256(abi.encodePacked(nFTContract, tokenId, _msgSender(), releaseTime));
        if (sellForEnabled) {
            require(sellFor > 0, 'Zero price is not allowed');
        }
        // check that sender is qualified
        require(_isTokenApproved(nFTContract, tokenId), 'Marketplace is not allowed to transfer your token');

        // transfer token to contract

        require(
            _excuteTransfer(_msgSender(), nFTContract, tokenId, address(this), address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );

        // update reserved
        // create auction

        require(
            _creatAuction(
                listId,
                nFTContract,
                _msgSender(),
                tokenId,
                listingPrice,
                sellForEnabled,
                sellFor,
                releaseTime,
                qualifyAmount
            ),
            "Couldn't list the item"
        );
        emit CreateAuction(
            listId,
            nFTContract,
            _msgSender(),
            tokenId,
            listingPrice,
            sellForEnabled,
            sellFor,
            releaseTime,
            qualifyAmount,
            block.timestamp
        );
    }

    /**
     * @dev  called by dapps to create  new auction
     * @param nFTContract nft contract address
     * @param tokenId token id
     * @param listingPrice min price
     * @param qualifyAmount  amount of token locked as qualify for any bidder wants bid
     * @param sellForEnabled true if auction enable direct selling
     * @param sellFor  price  to sell with if sellForEnabled=true
     * @param duration  when auction ends
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return listId listing id
     */
    function createAuctionWithPremit(
        address nFTContract,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 qualifyAmount,
        bool sellForEnabled,
        uint256 sellFor,
        uint256 duration,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 listId) {
        require(_premitNFT(nFTContract, _msgSender(), tokenId, deadline, v, r, s), 'invalid signature');
        listId = createAuction(nFTContract, tokenId, listingPrice, qualifyAmount, sellForEnabled, sellFor, duration);
    }

    /**
     * @dev called by dapps to bid on an auction
     *
     * @param listingId listing id
     * @param bidPrice price
     * @return bidId bid id
     */
    function bid(bytes32 listingId, uint256 bidPrice) external isOpenAuction(listingId) returns (bytes32 bidId) {
        address tokenAddress = _tokenListings[listingId].nFTContract;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        bidId = keccak256(abi.encodePacked(listingId, tokenAddress, _msgSender(), tokenId));
        // bid should be more than than the mini and more than the last bid
        address lastbidder = bidToListing[listingId].bidder;
        uint256 qualifyAmount = _tokenListings[listingId].qualifyAmount;
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
                _getStakeAllowance(
                    _msgSender() /*, 0*/
                ) >= qualifyAmount,
                'Not enough reserves'
            );
            bytes32[] storage listings = userListing[_msgSender()];
            listings.push(listingId);
            userListing[_msgSender()] = listings;
            // update user reserves
            // reserve Zero couldn't be at any case
            require(_updateUserReserves(_msgSender(), qualifyAmount, true) > 0, 'Reserve Zero is not allowed');
        }

        // bid
        require(_bid(bidId, listingId, tokenAddress, _msgSender(), tokenId, bidPrice), "Couldn't Bid");
        emit BidOnAuction(bidId, listingId, tokenAddress, _msgSender(), tokenId, bidPrice, block.timestamp);

        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }

    /**
     * @dev called by bidder through dapps when bidder win an auction and wants to pay to get the NFT
     *
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     */
    function fullfillBid(bytes32 listingId)
        public
        canFullfillBid(listingId)
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
        // transfer price
        address issuer;
        uint256 royaltyAmount;
        uint256 fees;
        uint256 netPrice;
        if (offerTerms[_msgSender()].fee != 0) {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                bidPrice,
                offerTerms[_msgSender()].fee,
                offerTerms[_msgSender()].feeBase
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
        require(
            _excuteTransfer(_msgSender(), _NFTContract, tokenId, seller, issuer, royaltyAmount, fees, netPrice, true),
            'StartFi: could not excute transfer'
        );

        // update user reserves
        // reserve nigative couldn't be at any case
        require(
            _updateUserReserves(winnerBidder, _tokenListings[listingId].qualifyAmount, false) >= 0,
            'negative reserve is not allowed'
        );

        // TODO: add reputation points to both seller and buyer
        _addreputationPoints(seller, winnerBidder, bidPrice);

        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit FullfillBid(
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
            if (issuer != address(0)) {
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
    function fullfillBidWithPremit(
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

        return fullfillBid(listingId);
    }

    // delist

    /**
     * @dev called by seller through dapps when s/he wants to remove this token from the marketplace
     * @notice auction can't be canceled , if seller delist time on sale on maretplace before time to delist, he will pay a fine
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     */
    function deList(bytes32 listingId) external returns (address _NFTContract, uint256 tokenId) {
        ListingStatus status = _tokenListings[listingId].status;
        address buyer = _tokenListings[listingId].buyer;
        address _owner = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        uint256 releaseTime = _tokenListings[listingId].releaseTime;
        uint256 listingPrice = _tokenListings[listingId].listingPrice;
        tokenId = _tokenListings[listingId].tokenId;
        require(_owner == _msgSender(), 'Caller is not the owner');
        require(buyer == address(0), 'Already bought token');
        uint256 timeToDelistAuction = StartFiFinanceLib._calcSum(releaseTime, 3 days);

        // require(status==ListingStatus.OnMarket || status==ListingStatus.onAuction,"Already bought or canceled token");
        require(
            (timeToDelistAuction <= block.timestamp && status == ListingStatus.onAuction) ||
                (status == ListingStatus.OnMarket),
            "Can't delist"
        );
        uint256 fineAmount;
        uint256 remaining;
        // if realse time < now , pay
        if (status != ListingStatus.onAuction) {
            if (releaseTime < block.timestamp) {
                // if it's not auction ? pay,
                if (offerTerms[_msgSender()].fee != 0) {
                    (fineAmount, remaining) = StartFiFinanceLib._getDeListingQualAmount(
                        listingPrice,
                        offerTerms[_msgSender()].delistFeesPercentage,
                        offerTerms[_msgSender()].delistFeesPercentageBase,
                        offerTerms[_msgSender()].listqualifyPercentage,
                        offerTerms[_msgSender()].listqualifyPercentageBase
                    );
                } else {
                    (fineAmount, remaining) = StartFiFinanceLib._getDeListingQualAmount(
                        listingPrice,
                        delistFeesPercentage,
                        delistFeesPercentageBase,
                        listqualifyPercentage,
                        listqualifyPercentageBase
                    );
                }

                //TODO: deduct the fine from his stake contract

                require(_deduct(_owner, _adminWallet, fineAmount), "couldn't deduct the fine");
            } else {
                if (offerTerms[_msgSender()].fee != 0) {
                    remaining = StartFiFinanceLib._calcFees(
                        listingPrice,
                        offerTerms[_msgSender()].listqualifyPercentage,
                        offerTerms[_msgSender()].listqualifyPercentageBase
                    );
                } else {
                    remaining = StartFiFinanceLib._calcFees(
                        listingPrice,
                        listqualifyPercentage,
                        listqualifyPercentageBase
                    );
                }
            }
            // update user reserves
            // reserve nigative couldn't be at any case
            require(_updateUserReserves(_msgSender(), remaining, false) >= 0, 'negative reserve is not allowed');
        }

        // trnasfer token

        require(
            _excuteTransfer(address(this), _NFTContract, tokenId, _owner, address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );
        // finish listing
        _finalizeListing(listingId, address(0), ListingStatus.Canceled);
        emit DeListOffMarketplace(
            listingId,
            _NFTContract,
            _owner,
            tokenId,
            fineAmount,
            remaining,
            releaseTime,
            block.timestamp
        );
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }

    // buynow
    /**
     * @dev called by buyer through dapps when s/he wants to buy a gevin NFT  token from the marketplace
     * @notice  if auction, the seller must enabe forSale. prices should be more than or equal the listing price
     * @param listingId listing id
     * @param price gevin price
     * @return _NFTContract nft contract address
     * @return tokenId token id
     */
    function buyNow(bytes32 listingId, uint256 price) public returns (address _NFTContract, uint256 tokenId) {
        if (price > stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }
        bool sellForEnabled = _tokenListings[listingId].sellForEnabled;
        address seller = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        require(price >= _tokenListings[listingId].listingPrice, 'Invalid price');
        require(
            _tokenListings[listingId].status == ListingStatus.OnMarket ||
                (_tokenListings[listingId].status == ListingStatus.onAuction &&
                    sellForEnabled == true &&
                    _tokenListings[listingId].releaseTime > block.timestamp),
            'Token isnot for sale '
        );
        // check that contract is allowed to transfer tokens
        require(
            _getAllowance(_msgSender()) >= price,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        address issuer;
        uint256 royaltyAmount;
        uint256 fees;
        uint256 netPrice;
        uint256 ListingQualAmount;
        // transfer price
        if (offerTerms[_msgSender()].fee != 0) {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                price,
                offerTerms[_msgSender()].fee,
                offerTerms[_msgSender()].feeBase
            );

            ListingQualAmount = StartFiFinanceLib._calcFees(
                _tokenListings[listingId].listingPrice,
                offerTerms[_msgSender()].listqualifyPercentage,
                offerTerms[_msgSender()].listqualifyPercentageBase
            );
        } else {
            (issuer, royaltyAmount, fees, netPrice) = StartFiFinanceLib._getListingFinancialInfo(
                _NFTContract,
                tokenId,
                price,
                _feeFraction,
                _feeBase
            );

            ListingQualAmount = StartFiFinanceLib._calcFees(
                _tokenListings[listingId].listingPrice,
                listqualifyPercentage,
                listqualifyPercentageBase
            );
        }
        require(
            _excuteTransfer(_msgSender(), _NFTContract, tokenId, seller, issuer, royaltyAmount, fees, netPrice, true),
            'StartFi: could not excute transfer'
        );

        require(_updateUserReserves(seller, ListingQualAmount, false) >= 0, 'negative reserve is not allowed');

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
            sellForEnabled,
            issuer,
            royaltyAmount,
            fees,
            netPrice,
            block.timestamp
        );
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
    }

    // buynow
    /**
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
        buyNow(listingId, price);
    }

    /**
     * @dev called by seller through dapps when his/her auction is  not fullfilled after 3 days
     *  @notice  after auction with winner bid . bidder didn't call fullfile within 3 days of auction closing  auction owner can call dispute to delist and punish the spam winner bidder fine is share between the plateform and the auction owner
     * @param listingId listing id
     * @return _NFTContract nft contract address
     * @return tokenId token id
     */
    function disputeAuction(bytes32 listingId) external returns (address _NFTContract, uint256 tokenId) {
        address winnerBidder = bidToListing[listingId].bidder;
        address seller = _tokenListings[listingId].seller;
        _NFTContract = _tokenListings[listingId].nFTContract;
        tokenId = _tokenListings[listingId].tokenId;
        uint256 qualifyAmount = _tokenListings[listingId].qualifyAmount;
        uint256 timeToDispute = _tokenListings[listingId].disputeTime;
        require(winnerBidder != address(0) && timeToDispute >= block.timestamp, 'No bids or still running auction');
        require(seller == _msgSender(), 'Caller is not the owner');
        require(!listingBids[listingId][winnerBidder].isPurchased, 'Already purchased');
        // call staking contract to deduct
        uint256 fineAmount;
        uint256 remaining;
        if (offerTerms[_msgSender()].fee != 0) {
            (fineAmount, remaining) = StartFiFinanceLib._calcBidDisputeFees(
                qualifyAmount,
                offerTerms[_msgSender()].bidPenaltyPercentage,
                offerTerms[_msgSender()].bidPenaltyPercentageBase
            );
        } else {
            (fineAmount, remaining) = StartFiFinanceLib._calcBidDisputeFees(
                qualifyAmount,
                bidPenaltyPercentage,
                bidPenaltyPercentageBase
            );
        }

        require(_deduct(winnerBidder, _adminWallet, fineAmount), "couldn't deduct the fine for the admin wallet");
        require(_deduct(winnerBidder, seller, remaining), "couldn't deduct the fine for the admin wallet");
        // trnasfer token
        require(
            _excuteTransfer(address(this), _NFTContract, tokenId, seller, address(0), 0, 0, 0, false),
            "NFT token couldn't be transfered"
        );

        require(_updateUserReserves(winnerBidder, qualifyAmount, false) >= 0, 'negative reserve is not allowed');

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
            qualifyAmount,
            remaining,
            fineAmount,
            block.timestamp
        );
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
        uint256 lastReserves = userReserves[_msgSender()];
        bytes32[] memory listings = userListing[_msgSender()];
        delete userListing[_msgSender()];
        bytes32[] storage newListings = userListing[_msgSender()];

        // loop
        for (uint256 index = 0; index < listings.length; index++) {
            if (_tokenListings[listings[index]].status == ListingStatus.onAuction) {
                newListings.push(listings[index]);
                curentReserves = StartFiFinanceLib._calcSum(
                    curentReserves,
                    _tokenListings[listings[index]].qualifyAmount
                );
            } else if (_tokenListings[listings[index]].status == ListingStatus.OnMarket) {
                newListings.push(listings[index]);
                uint256 listQualifyAmount = StartFiFinanceLib._calcFees(
                    _tokenListings[listings[index]].listingPrice,
                    listqualifyPercentage,
                    listqualifyPercentageBase
                );

                curentReserves = StartFiFinanceLib._calcSum(curentReserves, listQualifyAmount);
            }
        }
        userListing[_msgSender()] = newListings;
        require(_setUserReserves(_msgSender(), curentReserves), 'set reserve faild');
        emit UserReservesFree(_msgSender(), lastReserves, curentReserves, block.timestamp);
    }

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param duration duration
     *
     */
    function changeDelistAfter(uint256 duration) external onlyOwner whenPaused {
        _changeDelistAfter(duration);
    }

    /**
     * @dev only called by `owner` to approve listing that exceeded cap
     *@param listingId listing Id
     *
     */
    function approveDeal(bytes32 listingId) external onlyOwner {
        require(
            _tokenListings[listingId].status == ListingStatus.onAuction ||
                _tokenListings[listingId].status == ListingStatus.OnMarket,
            'StartFiMarketplace: Invalid ITem'
        );
        if (_tokenListings[listingId].status == ListingStatus.onAuction) {
            require(_tokenListings[listingId].releaseTime < block.timestamp, 'Auction is ended');
            _tokenListings[listingId].disputeTime = StartFiFinanceLib._calcSum(block.timestamp, 3 days);
        }
        kycedDeals[listingId] = true;
    }

    /**
     *  @dev only called by `owner` or `priceFeeds` to update the STFI/usdt price
     * @param _usdCap  the new fees value to be stored
     * @param _stfiCap  the new basefees value to be stored
     */
    function setCap(uint256 _usdCap, uint256 _stfiCap) external {
        require(
            hasRole(OWNER_ROLE, _msgSender()) || hasRole(PRICE_FEEDER_ROLE, _msgSender()),
            'StartFiMarketPlace: UnAuthorized caller'
        );

        _setCap(_usdCap, _stfiCap);
        // set
        stfiUsdt = StartFiFinanceLib.getUSDPriceInSTFI(_usdCap, _stfiCap);
    }
    // // ubnormal isssue with calling owner() in deList unction , we have implemented this func as a workaround
    // function getAdminWallet() private view returns (address) {
    //     return owner();
    // }
}
