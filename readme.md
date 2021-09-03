## StartFi core contracts 
==========================
- Startfi Marketplace contract eip-2612 support
- Startfi ERC721 token with royalty and eip-2612 support
- Sratfi ERC20 token with eip-2612 support 
- Startfi Staking contract [InProgress]
- STartFi Reputation Contract [InProgress]
- Startfi Reward contract [InProgress]
- Startfi Launchpad contract [ToDo]
- Startfi Governance token contract [ToDo]
- Startfi LP contract [ToDo]

## Startfi Marketplace contract 
==========================

All payments are done via $STFI and no other tokens or coins are supported to pay with. Thus, our user needs to hold token in order to participate. Some operations (list on marketplace with fix price and bid on auctions) are granted only for those who stake some STFI tokens. We are enforcing that as insurance to secure our users. To incentive the user to act positively  we provide a reputation points on each successful purchase which could be used to claim some tokens as reward in our reward program / used as voting power [toBeFinalized]    


The contract provide the following functionalities 

- [listOnMarketplace]: Users who want to list their NFT for sale with fixed price call this function 
    - user MUST approve contract to transfer the NFT     
    - user MUST have enough stakes used as insurance to not delist the item before the duration stated in the smart contract , if they decided to delist before that time, they lose this insurance. the required insurance amount is a percentage  based on the listing price.
- [listOnMarketplaceWithPremit]: Users who want to list their NFT for sale with fixed price call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [eip-2612] then call [listOnMarketplace] internally

- [createAuction]: Users who want to list their NFT as auction for bidding with/without allowing direct sale.
    - user MUST approve contract to transfer the NFT     
    - Time to live auction duration must be more than 12 hours.
    - if `sellForEnabled` is true, `sellFor` value must be more than zero
    - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI. 
- [createAuctionWithPremit]: Users who want to list their NFT as auction for bidding with/without allowing direct sale call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [eip-2612] then call [createAuction] internally.
- [bid]: Users who interested in a certain auction, can bid on it by calling this function.Bidder don't pay / transfer SFTI on bidding. Only when win the auction [the auction is ended and this bidder is the last one to bid], bidder pays by calling [fulfillBid] OR [buyNowWithPremit]
    - user MUST have enough stakes used as insurance; grantee and punishment mechanism for malicious bidder. If the bidder don't pay in the  
    - Bidders can bid as much as they wants , insurance is taken once in the first participation 
    - the bid price MUST be more than the last bid , if this is the first bid, the bid price MUST be more than or equal the minimum bid the auction creator state
    - Users CAN NOT bid on auction after auction time is over
- [fulfillBid]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT
    - user MUST approve contract to transfer the STFI token , MUST NOT be less than the bid price     
    - Time to live auction duration must be more than 12 hours.
    - if `sellForEnabled` is true, `sellFor` value must be more than zero
    - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI. 
- [fulfillBidWithPremit]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT, they call this function without sending prior transaction to `approve` the marketplace to transfer STFI. This function call`permit` [eip-2612] then call [fulfillBid] internally.
- [fulfillBid]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT
    - user MUST approve contract to transfer the STFI token , MUST NOT be less than the bid price     
    - Time to live auction duration must be more than 12 hours.
    - if `sellForEnabled` is true, `sellFor` value must be more than zero
    - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI. 
- [fulfillBidWithPremit]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT, they call this function without sending prior transaction to `approve` the marketplace to transfer STFI. This function call`permit` [eip-2612] then call [fulfillBid] internally.

- [disputeAuction]: If the winning bidder didn't pay withing the time range stated in te contract, Auction creator call this function to get the nft back and punish the malicious bidder bay taking the insurance (50% goes to the auction staking balance, 50% goes to the platform)
    - Current time  MUST be more than or equal the `disputeTime` for this auction     
    - Only auction Creator can dispute.


- [migrateEmergency]:
## How to use?
==========================
1. clone `git clone git@github.com:StartFi/core-with-hardhat.git` 
2. run `npm i `
3. to compile , run ` npx hardhat compile`
4. To deploy to hardhat, run `npx hardhat deploy`
5. To deploy to certain network . eg. aurora, run `npx hardhat --network testnet_aurora deploy `