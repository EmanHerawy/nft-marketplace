// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import './MarketPlaceListing.sol';
import './MarketPlaceBid.sol';
import './StartFiMarketPlaceSpecialOffer.sol';
import './interface/IERC721.sol';

import './library/StartFiFinanceLib.sol';
import './interface/IERC20.sol';

/**
 
 *@title StartFi MarketPlace
 *desc  marketplace with all functions for item selling by either ceating auction or selling with fixed prices, the contract auto transfer orginal NFT issuer's shares
 *
 */
contract StartFiMarketPlace is StartFiMarketPlaceSpecialOffer, MarketPlaceListing, MarketPlaceBid {
    /******************************************* decalrations go here ********************************************************* */
    //
    uint256 public listingCounter;
    // events when auction created auction bid auction cancled auction fullfiled item listed , item purchesed , item delisted ,  item  disputed , user release reserved ,
    ///

    event DeListOffMarketplace(bytes32 listId, address token, address owner, uint256 tokenId, uint256 timestamp);
    event MigrateEmergency(
        bytes32 listId,
        address token,
        address owner,
        uint256 tokenId,
        uint256 fineFees,
        uint256 releaseTime,
        uint256 timestamp
    );

    event ListOnMarketplace(
        bytes32 listId,
        address indexed token,
        address seller,
        uint256 indexed tokenId,
        uint256 listingPrice,
        uint256 timestamp
    );
    event CreateAuction(
        bytes32 listId,
        address indexed token,
        address seller,
        uint256 indexed tokenId,
        uint256 listingPrice,
        uint256 minimumBid,
        uint256 releaseTime,
        uint256 insuranceAmount,
        uint256 timestamp
    );

    event BidOnAuction(bytes32 bidId, bytes32 indexed listingId, address bidder, uint256 bidPrice, uint256 timestamp);

    event FulfillBid(
        bytes32 bidId,
        bytes32 indexed listingId,
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
        bytes32 indexed listingId,
        address tokenAddress,
        address bidder,
        uint256 tokenId,
        address seller,
        uint256 insuranceAmount,
        uint256 remaining,
        uint256 finefees,
        uint256 timestamp
    );

    event BuyNow(
        bytes32 indexed listId,
        address token,
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 sellingPrice,
        address issuer,
        uint256 royaltyAmount,
        uint256 fees,
        uint256 netPrice,
        uint256 timestamp
    );

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _marketPlaceName,
        address _paymentContract,
        address _stakeContract,
        address adminWallet
    ) {
        _MarketplaceBase_init_unchained(_marketPlaceName);
        _MarketplaceAdmin_init_unchained(adminWallet);
        _MarketplaceFinance_init_unchained(_paymentContract);
        stakeContract = _stakeContract;
        // to be removed
        _usdCap = 10000;
        _stfiCap = 50000;
        _stfiUsdt = 5;
    }

    // function initialize (
    //     string memory _marketPlaceName,
    //     address _paymentContract,
    //     address _stakeContract,
    //     address _reputationContract,
    //     address adminWallet
    // ) public /*onlyOwner*/ virtual initializer {
    //     _Marketplace_init_unchained(
    //         _marketPlaceName,
    //         _paymentContract,
    //         _stakeContract,
    //         _reputationContract,
    //         adminWallet
    //     );
    // }

    // function _Marketplace_init_unchained(
    //     string memory _marketPlaceName,
    //     address _paymentContract,
    //     address _stakeContract,
    //     address _reputationContract,
    //     address adminWallet
    // ) private {
    //     _MarketplaceBase_init_unchained(_marketPlaceName);
    //     _MarketplaceAdmin_init_unchained(adminWallet);
    //     _MarketplaceFinance_init_unchained(_paymentContract, _reputationContract);
    //     stakeContract = _stakeContract;
    //     // to be removed
    //     _usdCap = 10000;
    //     stfiCap = 50000;
    //     stfiUsdt = 5;
    // }

    /******************************************* modifiers go here ********************************************************* */

    modifier isNotZero(uint256 val) {
        require(val > 0, 'Zero Value is not allowed');
        _;
    }

    /******************************************* read state functions go here ********************************************************* */

    /******************************************* state functions go here ********************************************************* */

    // // list
    /**
     * @dev  called by dapps to list new item
     * @param token nft contract address
     * @param tokenId token id
     * @param listingPrice min price
      **
      Users who want to list their NFT for sale with fixed price call this function 
    - user MUST approve contract to transfer the NFT     
    - user MUST have enough stakes used as insurance to not delist the item before the duration stated in the smart contract , if they decided to delist before that time, they lose this insurance. the required insurance amount is a percentage  based on the listing price.
    ** 
    emit : ListOnMarketplace
     */
    function listOnMarketplace(
        address token,
        uint256 tokenId,
        uint256 listingPrice
    ) public whenNotPaused isNotZero(listingPrice) {
        listingCounter++;
        bytes32 listId = keccak256(abi.encodePacked(token, tokenId, _msgSender(), block.timestamp, listingCounter));
        listings.push(listId);
        require(
            IERC721(token).getApproved(tokenId) == address(this) ||
                IERC721(token).isApprovedForAll(_msgSender(), address(this)),
            'Marketplace is not allowed to transfer your token'
        );

        _tokenListings[listId] = Listing(
            token,
            _msgSender(),
            address(0),
            tokenId,
            listingPrice,
            block.timestamp,
            0,
            0,
            0,
            ListingType.FixedPrice,
            ListingStatus.OnMarket
        );
        emit ListOnMarketplace(listId, token, _msgSender(), tokenId, listingPrice, block.timestamp);
        IERC721(token).safeTransferFrom(_msgSender(), address(this), tokenId);
    }

    // list
    /**
     * @dev  called by dapps to list new item
     * @param token nft contract address
     * @param tokenId token id
     * @param listingPrice min price
      * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
      **
     Users who want to list their NFT for sale with fixed price call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`listOnMarketplace`] internally
     **
     */
    function listOnMarketplaceWithPermit(
        address token,
        uint256 tokenId,
        uint256 listingPrice,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(_permitNFT(token, _msgSender(), tokenId, deadline, v, r, s), 'invalid signature');
        listOnMarketplace(token, tokenId, listingPrice);
    }

    // create auction
    /**
     * @dev  called by dapps to create  new auction
     * @param token nft contract address
     * @param tokenId token id
     * @param minimumBid minimum Bid price
     * @param insuranceAmount  amount of token locked as qualify for any bidder wants bid
     * @param isSellForEnabled true if auction enable direct selling
     * @param listingPrice  price  to sell with if isSellForEnabled=true
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
        address token,
        uint256 tokenId,
        uint256 minimumBid,
        uint256 insuranceAmount,
        bool isSellForEnabled,
        uint256 listingPrice,
        uint256 duration
    ) public whenNotPaused isNotZero(minimumBid) returns (bytes32 listId) {
        ListingType _type;

        if (isSellForEnabled) {
            require(listingPrice >= minimumBid, 'Zero price is not allowed');
            _type = ListingType.AuctionForSale;
        } else {
            listingPrice = 0;
            _type = ListingType.Auction;
        }
        require(duration > 12 hours, 'Auction should be live for more than 12 hours');
        require(insuranceAmount >= _stfiUsdt, 'Invalid Auction qualify Amount');
        uint256 releaseTime = block.timestamp + duration;
        listingCounter++;
        listId = keccak256(abi.encodePacked(token, tokenId, _msgSender(), releaseTime, listingCounter));
        listings.push(listId);

        // check that sender is qualified
        require(
            IERC721(token).getApproved(tokenId) == address(this) ||
                IERC721(token).isApprovedForAll(_msgSender(), address(this)),
            'Marketplace is not allowed to transfer your token'
        );

        // update reserved
        // create auction
        _tokenListings[listId] = Listing(
            token,
            _msgSender(),
            address(0),
            tokenId,
            listingPrice,
            releaseTime,
            releaseTime + fulfillDuration,
            insuranceAmount,
            minimumBid,
            _type,
            ListingStatus.OnMarket
        );

        emit CreateAuction(
            listId,
            token,
            _msgSender(),
            tokenId,
            listingPrice,
            minimumBid,
            releaseTime,
            insuranceAmount,
            block.timestamp
        );
        // transfer token to contract

        IERC721(token).safeTransferFrom(_msgSender(), address(this), tokenId);
    }

    /**
     * @dev  called by dapps to create  new auction
     * @param token nft contract address
     * @param tokenId token id
     * @param listingPrice min price
     * @param insuranceAmount  amount of token locked as qualify for any bidder wants bid
     * @param isSellForEnabled true if auction enable direct selling
     * @param minimumBid  price  to sell with if isSellForEnabled=true
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
    function createAuctionWithPermit(
        address token,
        uint256 tokenId,
        uint256 minimumBid,
        uint256 insuranceAmount,
        bool isSellForEnabled,
        uint256 listingPrice,
        uint256 duration,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 listId) {
        require(_permitNFT(token, _msgSender(), tokenId, deadline, v, r, s), 'invalid signature');
        listId = createAuction(token, tokenId, minimumBid, insuranceAmount, isSellForEnabled, listingPrice, duration);
    }

    /**
    ** Users who interested in a certain auction, can bid on it by calling this   function.Bidder don't pay / transfer SFTI on bidding. Only when win the auction [`the auction is ended and this bidder is the last one to bid`], bidder pays by calling [`fulfillBid`] OR [`buyNowWithPermit`]
    - user MUST have enough stakes used as insurance; grantee and punishment mechanism for malicious bidder. If the bidder don't pay in the  
    - Bidders can bid as much as they wants , insurance is taken once in the first participation 
    - the bid price MUST be more than the last bid , if this is the first bid, the bid price MUST be more than or equal the minimum bid the auction creator state
    - Users CAN NOT bid on auction after auction time is over
    
    **
     * @dev called by dapps to bid on an auction
     *
     * @param listingId listing id
     * @param bidPrice price
     * emit : BidOnAuction
     */
    function bid(bytes32 listingId, uint256 bidPrice) external whenNotPaused {
        require(
            _tokenListings[listingId].releaseTime > block.timestamp &&
                _tokenListings[listingId].status == ListingStatus.OnMarket &&
                _tokenListings[listingId].listingType != ListingType.FixedPrice,
            'Auction is ended'
        );
        // bidder has bid before ?
        address lastbidder = bidToListing[listingId].bidder;

        if (lastbidder == address(0)) {
            require(
                bidPrice >= _tokenListings[listingId].minimumBid,
                'bid price must be more than or equal the minimum price'
            );
        } else {
            require(bidPrice > listingBids[listingId][lastbidder].bidPrice, 'bid price must be more than the last bid');
        }
        bytes32 bidId;
        if (!listingBids[listingId][_msgSender()].isStakeReserved) {
            bidId = keccak256(
                abi.encodePacked(
                    listingId,
                    _tokenListings[listingId].token,
                    _msgSender(),
                    _tokenListings[listingId].tokenId
                )
            );
            uint256 insuranceAmount = _tokenListings[listingId].insuranceAmount;
            require(
                _getStakeAllowance(
                    _msgSender() /*, 0*/
                ) >= insuranceAmount,
                'Not enough reserves'
            );

            // update user reserves
            // reserve Zero couldn't be at any case
            userReserves[_msgSender()] += insuranceAmount;
            listingBids[listingId][_msgSender()].isStakeReserved = true;
        } else {
            bidId = listingBids[listingId][lastbidder].bidId;
        }

        // bid should be more than than the mini and more than the last bid

        // if this is the bidder first bid, the price will be 0

        // bid
        bidToListing[listingId] = WinningBid(bidId, _msgSender());
        // set isStakeReserved as true by default as the contract doesn't call this fucntion unless required checks have been done and met
        listingBids[listingId][_msgSender()] = Bid(bidId, bidPrice, false, true);

        emit BidOnAuction(bidId, listingId, _msgSender(), bidPrice, block.timestamp);

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
 
     */
    function fulfillBid(bytes32 listingId) public whenNotPaused {
        require(
            _tokenListings[listingId].releaseTime < block.timestamp &&
                _tokenListings[listingId].listingType != ListingType.FixedPrice,
            'Auction is not ended or no longer on auction'
        );
        address winnerBidder = bidToListing[listingId].bidder;
        address seller = _tokenListings[listingId].seller;
        address _token = _tokenListings[listingId].token;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        uint256 bidPrice = listingBids[listingId][winnerBidder].bidPrice;
        uint256 insuranceAmount = _tokenListings[listingId].insuranceAmount;

        require(winnerBidder == _msgSender(), 'Caller is not the winner');
        // if it's new, the price will be 0
        if (bidPrice > _stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }
        //check that contract is allowed to transfer tokens
        require(
            IERC20(_paymentToken).allowance(winnerBidder, address(this)) >= bidPrice,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        StartFiFinanceLib.ShareInput memory _input;
        _input.tokenId = tokenId;
        _input.token = _token;
        _input.price = bidPrice;
        (_input.fee, _input.feeBase) = _getFees(seller);

        StartFiFinanceLib.ShareOutput memory _output = StartFiFinanceLib._getListingFinancialInfo(_input);

        listingBids[listingId][winnerBidder].isStakeReserved = false;
        listingBids[listingId][winnerBidder].isPurchased = true;
        _tokenListings[listingId].status = ListingStatus.Sold;
        _tokenListings[listingId].buyer = winnerBidder;

        // update user reserves
        // reserve nigative couldn't be at any case

        userReserves[winnerBidder] -= insuranceAmount;

        //   TODO: add reputation points to both seller and buyer
        // _addreputationPoints(seller, winnerBidder, bidPrice);

        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit FulfillBid(
            bidToListing[listingId].bidId,
            listingId,
            _token,
            winnerBidder,
            tokenId,
            bidPrice,
            _output.issuer,
            _output.royaltyAmount,
            _output.fees,
            _output.netPrice,
            block.timestamp
        );

        require(
            IERC20(_paymentToken).transferFrom(_msgSender(), _adminWallet, _output.fees),
            "Couldn't transfer token as fees"
        );
        // if the issuer is the seller , no need to send two 2 transfer transaction , let's do it 1 to reduce gas
        if (_output.issuer == seller) {
            _output.netPrice += _output.royaltyAmount;
        } else if (_output.issuer != address(0) && _output.royaltyAmount != 0) {
            require(
                IERC20(_paymentToken).transferFrom(_msgSender(), _output.issuer, _output.royaltyAmount),
                "Couldn't transfer token to issuer"
            );
        }
        require(
            IERC20(_paymentToken).transferFrom(_msgSender(), seller, _output.netPrice),
            "Couldn't transfer token to seller"
        );
        IERC721(_token).safeTransferFrom(address(this), _msgSender(), tokenId);
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
  

     */
    function fulfillBidWithPermit(
        bytes32 listingId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20(_paymentToken).permit(
            _msgSender(),
            address(this),
            listingBids[listingId][_msgSender()].bidPrice,
            deadline,
            v,
            r,
            s
        );

        fulfillBid(listingId);
    }

    // delist

    /**
    ** Users who no longer want to keep their NFT in our marketplace can easly call this function to get their NFT back. Unsuccessful auction creators need to call it as well to get their nft back with no cost as well as the item added via [`listOnMarketplace`] or [`listOnMarketplaceWithPermit`]  
    - Only buyers can delist their own items 
    - Auction items can't delisted until the auction ended
    **
     * @dev called by seller through dapps when s/he wants to remove this token from the marketplace
     * @notice auction can't be canceled , if seller delist time on sale on maretplace before time to delist, he will pay a fine
     * @param listingId listing id

     * emit DeListOffMarketplace
     */
    function deList(bytes32 listingId) external whenNotPaused {
        ListingType _type = _tokenListings[listingId].listingType;
        ListingStatus status = _tokenListings[listingId].status;
        address buyer = _tokenListings[listingId].buyer;
        address _owner = _tokenListings[listingId].seller;
        address _token = _tokenListings[listingId].token;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        require(status == ListingStatus.OnMarket, 'Item is not on Auction or Listed for sale');

        require(_owner == _msgSender(), 'Caller is not the owner');
        require(buyer == address(0), 'Already bought token');

        if (_type != ListingType.FixedPrice) {
            uint256 releaseTime = _tokenListings[listingId].releaseTime;
            uint256 timeToDelistAuction = releaseTime + fulfillDuration;
            require((timeToDelistAuction <= block.timestamp), 'Not the time to Delist auction');
        }

        // finish listing
        _tokenListings[listingId].status = ListingStatus.Canceled;
        emit DeListOffMarketplace(listingId, _token, _owner, tokenId, block.timestamp);
        // trnasfer token

        IERC721(_token).safeTransferFrom(address(this), _msgSender(), tokenId);
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
     * emit : BuyNow
     */
    function buyNow(bytes32 listingId) public whenNotPaused {
        ListingStatus status = _tokenListings[listingId].status;
        ListingType _type = _tokenListings[listingId].listingType;
        uint256 price = _tokenListings[listingId].listingPrice;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        address seller = _tokenListings[listingId].seller;
        address _token = _tokenListings[listingId].token;
        require(status == ListingStatus.OnMarket && _type != ListingType.Auction, 'Item is not for sale');

        if (_type == ListingType.AuctionForSale) {
            require(_tokenListings[listingId].releaseTime > block.timestamp, 'Item is not for sale');
        }
        if (price > _usdCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }

        // check that contract is allowed to transfer tokens
        require(
            IERC20(_paymentToken).allowance(_msgSender(), address(this)) >= price,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        StartFiFinanceLib.ShareInput memory _input;
        _input.tokenId = tokenId;
        _input.token = _token;
        _input.price = price;
        (_input.fee, _input.feeBase) = _getFees(seller);

        StartFiFinanceLib.ShareOutput memory _output = StartFiFinanceLib._getListingFinancialInfo(_input);

        // finish listing
        _tokenListings[listingId].status = ListingStatus.Sold;
        _tokenListings[listingId].buyer = _msgSender();
        // _addreputationPoints(seller, _msgSender(), price);
        emit BuyNow(
            listingId,
            _token,
            _msgSender(),
            seller,
            tokenId,
            price,
            _output.issuer,
            _output.royaltyAmount,
            _output.fees,
            _output.netPrice,
            block.timestamp
        );
        require(
            IERC20(_paymentToken).transferFrom(_msgSender(), _adminWallet, _output.fees),
            "Couldn't transfer token as fees"
        );
        // if the issuer is the seller , no need to send two 2 transfer transaction , let's do it 1 to reduce gas
        if (_output.issuer == seller) {
            _output.netPrice += _output.royaltyAmount;
        } else if (_output.issuer != address(0) && _output.royaltyAmount != 0) {
            require(
                IERC20(_paymentToken).transferFrom(_msgSender(), _output.issuer, _output.royaltyAmount),
                "Couldn't transfer token to issuer"
            );
        }

        // token value could be zero ater taking the roylty share ??? need to ask?
        require(
            IERC20(_paymentToken).transferFrom(_msgSender(), seller, _output.netPrice),
            "Couldn't transfer token to seller"
        );
        // trnasfer token
        IERC721(_token).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    // //
    // /**
    // **
    // Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can this call this function without sending prior transaction to `approve` the marketplace to transfer STFI tokens. This function call`permit` [`eip-2612`] then call [`buyNow`] internally.
    // **
    //  * @dev called by buyer through dapps when s/he wants to buy a gevin NFT  token from the marketplace
    //  * @notice  if auction, the seller must enabe forSale. prices should be more than or equal the listing price
    //  * @param listingId listing id
    //  * @param price gevin price
    //  * @param deadline:  must be timestamp in future .
    //  * @param v needed to recover the public key
    //  * @param r : normal output of an ECDSA signature
    //  * @param s: normal output of an ECDSA signature
    //  * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.

    function buyNowWithPermit(
        bytes32 listingId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20(_paymentToken).permit(_msgSender(), address(this), price, deadline, v, r, s);

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
     * @return _token nft contract address
     * @return tokenId token id
     * emit : DisputeAuction
     */
    function disputeAuction(bytes32 listingId) external whenNotPaused returns (address _token, uint256 tokenId) {
        address winnerBidder = bidToListing[listingId].bidder;

        address seller = _tokenListings[listingId].seller;
        _token = _tokenListings[listingId].token;
        ListingType _type = _tokenListings[listingId].listingType;
        tokenId = _tokenListings[listingId].tokenId;
        uint256 insuranceAmount = _tokenListings[listingId].insuranceAmount;
        uint256 timeToDispute = _tokenListings[listingId].disputeTime;
        require(seller == _msgSender(), 'Only Seller can dispute');
        require(
            _tokenListings[listingId].status == ListingStatus.OnMarket && _type != ListingType.FixedPrice,
            'Marketplace: Item is not on Auction'
        );
        require(winnerBidder != address(0), 'Marketplace: Auction has no bids');
        require(timeToDispute <= block.timestamp, 'Marketplace: Can not dispute before time');
        require(
            unpauseTimestamp + fulfillDuration < block.timestamp,
            'Contract has justed unpaused, please give the bidder time to fulfill'
        );

        if (listingBids[listingId][winnerBidder].bidPrice > _stfiCap) {
            require(kycedDeals[listingId], 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }
        //50% goes to the platform
        (uint256 fineAmount, uint256 remaining) = StartFiFinanceLib._calcBidDisputeFees(insuranceAmount);
        // call staking contract to deduct
        require(
            _deduct(winnerBidder, _adminWallet, fineAmount),
            "Marketplace: couldn't deduct the fine for the admin wallet"
        );
        require(_deduct(winnerBidder, seller, remaining), "Marketplace: couldn't deduct the fine for the admin wallet");
        listingBids[listingId][winnerBidder].isStakeReserved = false;
        userReserves[winnerBidder] -= insuranceAmount;

        // finish listing
        _tokenListings[listingId].status = ListingStatus.Canceled;
        // if bid time is less than 15 min, increase by 15 min
        // retuen bid id
        emit DisputeAuction(
            bidToListing[listingId].bidId,
            listingId,
            _token,
            winnerBidder,
            tokenId,
            seller,
            insuranceAmount,
            remaining,
            fineAmount,
            block.timestamp
        );
        // transfer token back
        IERC721(_token).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    /**
    ** users need to stake STFI to bid in the marketplace , these tokens needs to set release if the auction is no longer active and user can use these stakes to bid  thus, function to release tokens reserved to listing of market 
 *  in order to let user batch release many lisiting , they can call `releaseBatchReserves`
 * called by user/ third actors only when s/he wants rather than force the check & updates with every transaction which might be very costly .
   -  
   ** 
    * @dev called by user through dapps when his/her wants to release his reserved tokens which are no longer in active auction .
    *  @notice called by user or on behalf of the user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
     * @param listingId listing idbehalf
     * @param bidder bidder address
     * emit : UserReservesRelease
     */
    function releaseListingReserves(bytes32 listingId, address bidder) public {
        require(listingBids[listingId][bidder].bidPrice != 0, 'Bidder is not participating in this auction');
        require(listingBids[listingId][bidder].isStakeReserved, 'Already released');
        require(_tokenListings[listingId].releaseTime < block.timestamp, 'Can not release stakes for running auction');
        require(
            bidToListing[listingId].bidder != bidder,
            'Winner bidder can  only  release stakes by fulfilling the auction'
        );
        _releaseListingReserves(listingId, bidder);
    }

    function _releaseListingReserves(bytes32 listingId, address bidder) private {
        uint256 lastReserves = userReserves[bidder];
        uint256 insuranceAmount = _tokenListings[listingId].insuranceAmount;
        userReserves[bidder] -= insuranceAmount;

        listingBids[listingId][bidder].isStakeReserved = false;
        uint256 curentReserves = userReserves[bidder];
        emit UserReservesRelease(bidder, lastReserves, curentReserves, block.timestamp);
    }

    function releaseBatchReserves(bytes32[] memory listingIds, address bidder) external {
        for (uint256 index = 0; index < listingIds.length; index++) {
            releaseListingReserves(listingIds[index], bidder);
        }
    }

    /**
    *STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and any purchase transaction with price exceed the cap can't be proceed unless this deal is approved by Startfi by calling this function
- called only by account in owner role
     * @dev only called by `owner` to approve listing that exceeded cap after doing the KYC
     *@param listingId listing Id
     *@param status kyc status
     * emit HandelKyc
     */
    function approveDeal(bytes32 listingId, bool status) external onlyOwner whenNotPaused {
        require(_tokenListings[listingId].status == ListingStatus.OnMarket, 'StartFiMarketplace: Invalid item');
        /**
       we have the following scenario : 
       * auction bid get higher than the cap , and needs to get approved 
       * kyc process for anyreason takes some longer time that might exceed the time to dispute 
       * malicious auction creator call diputeAuction and winner bider loses money 
       * to protect we put condition on dispute to check if the bid price exceed cap and the deal is approved in order to proceed because at this case this is malicious bidder
       * second condition is in deal approval, if we have approved the deal before time to realse ( we are monitoring the marketplace when the auction bids exceed the cap , we can  ) 
       */
        if (status) {
            if (_tokenListings[listingId].listingType != ListingType.FixedPrice) {
                if (_tokenListings[listingId].releaseTime < block.timestamp) {
                    _tokenListings[listingId].disputeTime = block.timestamp + fulfillDuration;
                }
            }
            kycedDeals[listingId] = true;
        } else {
            address seller = _tokenListings[listingId].seller;
            kycedDeals[listingId] = false;
            _tokenListings[listingId].status = ListingStatus.Canceled;
            if (_tokenListings[listingId].listingType != ListingType.FixedPrice) {
                _releaseListingReserves(listingId, seller);
            }
            IERC721(_tokenListings[listingId].token).safeTransferFrom(
                address(this),
                seller,
                _tokenListings[listingId].tokenId
            );
        }
        emit HandelKyc(listingId, _msgSender(), status, block.timestamp);
    }

    /** **************************Emergency Zone ********************/

    /**
    **
    Only when contract is paused, users can safely delist their token with no cost. Startfi team might have to pause the contract to make any update on the protocol terms or in emergency if high risk vulnerability is discovered to protect the users.    
   - Only buyers can delist their own items 
   **
     * @dev called by seller through dapps when s/he wants to remove this token from the marketplace
     * @notice called only when puased , let user to migrate for release if they don't agree on our new terms
     * @param listingId listing id

     * emit : MigrateEmergency
     */
    function migrateEmergency(bytes32 listingId) external whenPaused {
        ListingStatus status = _tokenListings[listingId].status;
        address buyer = _tokenListings[listingId].buyer;
        address _owner = _tokenListings[listingId].seller;
        address _token = _tokenListings[listingId].token;
        uint256 releaseTime = _tokenListings[listingId].releaseTime;
        uint256 tokenId = _tokenListings[listingId].tokenId;
        require(_owner == _msgSender(), 'Caller is not the owner');
        require(buyer == address(0), 'Already bought token');
        require(status == ListingStatus.OnMarket, 'Already bought or canceled token');

        // finish listing
        _tokenListings[listingId].status = ListingStatus.Canceled;
        emit MigrateEmergency(
            listingId,
            _token,
            _owner,
            tokenId,
            _tokenListings[listingId].insuranceAmount,
            releaseTime,
            block.timestamp
        );
        IERC721(_token).safeTransferFrom(address(this), _owner, tokenId);
    }

    /**  private functions go here  */

    function _getFees(address seller) private view returns (uint256 fee, uint256 feeBase) {
        if (offerTerms[seller].fee != 0) {
            fee = offerTerms[seller].fee;
            feeBase = offerTerms[seller].feeBase;
        } else {
            fee = _feeFraction;
            feeBase = _feeBase;
        }
    }

    // erc721
    /**
     *
     * @dev  interal function to check if any gevin contract has supportsInterface See {IERC165-supportsInterface}.
     * @param _token NFT contract address
     * @return true if this NFT contract support royalty, false if not
     */
    function _supportPermit(address _token) private view returns (bool) {
        try IERC721(_token).supportsInterface(0x2a55205a) returns (bool isPermitSupported) {
            return isPermitSupported;
        } catch {
            return false;
        }
    }

    /**
    * @dev called by the contract to get who much token this contract is allowed to spend from the `owner` account
     * @param _token nft contract address
     * @param tokenId token id
     * @param target token owner
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return true when done, false if not
     */
    function _permitNFT(
        address _token,
        address target,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (bool) {
        if (_supportPermit(_token)) {
            return IERC721(_token).permit(target, address(this), tokenId, deadline, v, r, s);
        } else {
            return false;
        }
    }
}
