// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import '../interface/IERC721.sol';
import '../interface/IStartFiMarketPlace.sol';
import '../library/StartFiFinanceLib.sol';

import '../interface/IERC20.sol';
import './IMarketPlaceFixedPriceItem.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Listing
 * [ desc ] : contract handle all item list in marketplace related function
 */
contract MarketPlaceFixedPriceItem is IMarketPlaceFixedPriceItem {
    // all fees are in perentage
    address private immutable _operator;
    // store every listed item here
    bytes32[] public listings;
    IERC20 _paymentToken;
    modifier isOpenForSale(bytes32 listingId) {
        require(_tokenListings[listingId].status == ListingStatus.OnMarket, 'Item is not for sale');
        _;
    }

    constructor(address operator, address _paymentContract) {
        _operator = operator;
        _paymentToken = IERC20(_paymentContract);
    }

    // listing key  to lisitng details
    mapping(bytes32 => Listing) internal _tokenListings;

    modifier onlyOperator() {
        require(msg.sender == _operator, 'UnAuthorized');
        // require(_msgSender() == _operator, 'UnAuthorized');
        _;
    }

    /******************************************* read state functions go here ********************************************************* */
    /**
    * 
      * @dev   called by dapp or any contract to get info about a gevin listing    
      * @param listingId listing id      

       * @return seller  nft seller address
        */
    function getSeller(bytes32 listingId) external view override returns (address) {
        return _tokenListings[listingId].seller;
    }

    function getListingDetails(bytes32 listingId)
        external
        view
        override
        returns (
            address tokenAddress,
            address seller,
            address buyer,
            uint256 tokenId,
            uint256 listingPrice,
            uint256 status
        )
    {
        tokenAddress = _tokenListings[listingId].token;
        tokenId = _tokenListings[listingId].tokenId;
        listingPrice = _tokenListings[listingId].listingPrice;
        seller = _tokenListings[listingId].seller;
        buyer = _tokenListings[listingId].buyer;
        status = uint256(_tokenListings[listingId].status);
    }

    /** external functions that changes the state go here  */
    /// @dev only called by marketplace contract

    function deList(bytes32 listingId, address sender) external override onlyOperator returns (address, uint256) {
        require(_tokenListings[listingId].status == ListingStatus.OnMarket, 'Item is not Listed for sale');

        require(_tokenListings[listingId].seller == sender, 'Caller is not the owner');
        require(_tokenListings[listingId].buyer == address(0), 'Already bought token');

        // finish listing
        _tokenListings[listingId].status = ListingStatus.Canceled;
        return (_tokenListings[listingId].token, _tokenListings[listingId].tokenId);
    }

    function listItemOnMarket(
        bytes32 listId,
        address token,
        address seller,
        uint256 tokenId,
        uint256 listingPrice
    ) external override onlyOperator returns (bool) {
        require(
            IERC721(token).getApproved(tokenId) == _operator || IERC721(token).isApprovedForAll(seller, _operator),
            'Marketplace is not allowed to transfer your token'
        );
        _tokenListings[listId] = Listing(token, tokenId, listingPrice, seller, address(0), ListingStatus.OnMarket);
        return true;
    }

    function buyNow(
        bytes32 listingId,
        address buyer,
        uint256 cap,
        bool isKyced
    )
        external
        override
        onlyOperator
        returns (
            StartFiFinanceLib.ShareOutput memory _output,
            address token,
            address seller,
            uint256 tokenId,
            uint256 price
        )
    {
        seller = _tokenListings[listingId].seller;
        (uint256 fee, uint256 feeBase) = IStartFiMarketPlace(msg.sender).getFees(seller);
        price = _tokenListings[listingId].listingPrice;
        require(_tokenListings[listingId].status == ListingStatus.OnMarket);

        if (price > cap) {
            require(isKyced, 'StartfiMarketplace: Price exceeded the cap. You need to get approved');
        }

        // check that contract is allowed to transfer tokens
        require(
            _paymentToken.allowance(buyer, _operator) >= price,
            'Marketplace is not allowed to withdraw the required amount of tokens'
        );
        StartFiFinanceLib.ShareInput memory _input;
        _input.tokenId = _tokenListings[listingId].tokenId;
        _input.token = _tokenListings[listingId].token;
        _input.price = price;
        _input.fee = fee;
        _input.feeBase = feeBase;
        _tokenListings[listingId].status = ListingStatus.Sold;
        _tokenListings[listingId].buyer = buyer;
        _output = StartFiFinanceLib._getListingFinancialInfo(_input);

        // finish listing
    }
}
