## Contract to get audited

==========================

- Startfi Marketplace contract eip-2612 support
- Startfi ERC721 token with royalty and eip-2612 support
- Sratfi ERC20 token with eip-2612 support
- StartFi Token Distribution

## StartFi core contracts

==========================

- Startfi Marketplace contract eip-2612 support
- Startfi ERC721 token with royalty and eip-2612 support
- Sratfi ERC20 token with eip-2612 support
- StartFi Token Distribution
- Startfi Staking contract [`InProgress`]
- STartFi Reputation Contract [`InProgress`]
- Startfi Reward contract [`InProgress`]
- Startfi Launchpad contract [`ToDo`]
- Startfi Governance token contract [`ToDo`]
- Startfi LP contract [`ToDo`]

## Startfi Marketplace contract

==========================

All payments are done via STFI and no other tokens or coins are supported to pay with. Thus, our user needs to hold token in order to participate. Some operations (list on marketplace with fix price and bid on auctions) are granted only for those who stake some STFI tokens. We are enforcing that as insurance to secure our users. To incentive the user to act positively we provide a reputation points on each successful purchase which could be used to claim some tokens as reward in our reward program / used as voting power [`toBeFinalized`] . The marketplace auto transfer original NFT issuer's share if the token support royalty [`supportsRoyalty()`]

### The contract provide the following functionalities :

- [`listOnMarketplace`]: Users who want to list their NFT for sale with fixed price call this function
  - user MUST approve contract to transfer the NFT
  - user MUST have enough stakes used as insurance to not delist the item before the duration stated in the smart contract , if they decided to delist before that time, they lose this insurance. the required insurance amount is a percentage based on the listing price.
- [`listOnMarketplaceWithPermit`]: Users who want to list their NFT for sale with fixed price call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`listOnMarketplace`] internally

- [`createAuction`]: Users who want to list their NFT as auction for bidding with/without allowing direct sale.
  - user MUST approve contract to transfer the NFT
  - Time to live auction duration must be more than 12 hours.
  - if `sellForEnabled` is true, `sellFor` value must be more than zero
  - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI.
- [`createAuctionWithPermit`]: Users who want to list their NFT as auction for bidding with/without allowing direct sale call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`createAuction`] internally.
- [`bid`]: Users who interested in a certain auction, can bid on it by calling this function.Bidder don't pay / transfer SFTI on bidding. Only when win the auction [`the auction is ended and this bidder is the last one to bid`], bidder pays by calling [`fulfillBid`] OR [`buyNowWithPermit`]

  - user MUST have enough stakes used as insurance; grantee and punishment mechanism for malicious bidder. If the bidder don't pay in the
  - Bidders can bid as much as they wants , insurance is taken once in the first participation
  - the bid price MUST be more than the last bid , if this is the first bid, the bid price MUST be more than or equal the minimum bid the auction creator state
  - Users CAN NOT bid on auction after auction time is over

- [`fulfillBid`]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT
  - user MUST approve contract to transfer the STFI tokens , MUST NOT be less than the bid price
  - Winner bidder can call it within the `fulfillDuration` right after the end of the auction.
  - Winner bider can call it even after the its end as long as the auction reactor has not called dispute. the winner bidder can have chat with the seller and if the auction creator thinks the winner bidder is not a malicious bidder, they might agree to wait so we don't want to prevent the scenario where the can see eye to eye. At the end the auction creator wants to buy the NFT and get the price
  - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`]
- [`fulfillBidWithPermit`]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT, they call this function without sending prior transaction to `approve` the marketplace to transfer STFI. This function call`permit` [`eip-2612`] then call [`fulfillBid`] internally.

- [`disputeAuction`]: If the winning bidder didn't pay within the time range stated in te contract `fulfillDuration`, Auction creator calls this function to get the nft back and punish the malicious bidder by taking the insurance (50% goes to the auction staking balance, 50% goes to the platform)
  - Current time MUST be more than or equal the `disputeTime` for this auction
  - Only auction Creator can dispute.
  - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, and the auction is approved , auction creator can dispute, if it's not approved yet, auction creator can not.
- [`buyNow`]: Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can call this function.

  - User MUST approve contract to transfer the STFI token , MUST NOT be less than the price.
  - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`]

- [`buyNowWithPermit`]:Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can this call this function without sending prior transaction to `approve` the marketplace to transfer STFI tokens. This function call`permit` [`eip-2612`] then call [`buyNow`] internally.

- [`deList`]: Users who no longer want to keep their NFT in our marketplace can easly call this function to get their NFT back. Unsuccessful auction creators need to call it as well to get their nft back with no cost while the item added via [`listOnMarketplace`] or [`listOnMarketplaceWithPermit`] might lose the insurance amount if they decided to delist the items before the greed time stated in the contract `delistAfter`

  - Only buyers can delist their own items
  - Auction items can't delisted until the auction ended

- [`migrateEmergency`]: Only when contract is paused, users can safely delist their token with no cost. Startfi team might have to pause the contract to make any update on the protocol terms or in emergency if high risk vulnerability is discovered to protect the users.

  - Only buyers can delist their own items

- [`approveDeal`]: STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and any purchase transaction with price exceed the cap can't be proceed unless this deal is approved by Startfi by calling this function
- called only by account in owner role

- [`freeReserves`]:
  users need to stake STFI to list or bid in the marketplace , these tokens needs to set free if the auction is no longer active and user can use these stakes to bid , list or even to withdraw tokens thus, function to free tokens reserved to items of market

* in order to keep track of the on hold stakes.
* we store user on-hold stakes in a map `userReserves`
* to get user on-hold reserves call getUserReserved on marketplace
* to get the number of stakes that not on hold, call userReserves on marketplace , this function subtract the user stakes in staking contract from the on-hold stakes on marketplace
  \*This function is greedy, called by user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
  - Only users can free their own reserves

## How to use?

==========================

1. clone `git clone git@github.com:StartFi/core-with-hardhat.git`
2. run `npm i `
3. to compile , run ` npx hardhat compile`
4. to test , run ` npx hardhat test`
5. To deploy to hardhat, run `npx hardhat deploy`
6. To deploy to certain network . eg. aurora, run `npx hardhat --network testnet_aurora deploy `
