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

All payments are done via STFI and no other tokens or coins are supported to pay with. Thus, our user needs to hold token in order to participate. Some operations (list on marketplace with fix price and bid on auctions) are granted only for those who stake some STFI tokens. We are enforcing that as insurance to secure our users. To incentive the user to act positively  we provide a reputation points on each successful purchase which could be used to claim some tokens as reward in our reward program / used as voting power [`toBeFinalized`] . The marketplace  auto transfer original NFT issuer's share if the token support royalty [`supportsRoyalty()`]   


### The contract provide the following functionalities :
![image](https://user-images.githubusercontent.com/10674070/134208756-30a40a23-cd4b-4384-9cc0-947538149378.png)
![buyer-activities-digram](https://user-images.githubusercontent.com/10674070/134208819-ada71adf-be27-411d-ae43-dc45c87af16c.png)

![user-activity-digram](https://user-images.githubusercontent.com/10674070/134208601-ebb14e09-0881-44b3-81d0-c042c84de0b8.png)
![admin-activities-digram](https://user-images.githubusercontent.com/10674070/134208872-733cce5f-ec8e-408b-9845-825852a69014.png)


- [`listOnMarketplace`]: Users who want to list their NFT for sale with fixed price call this function 
    - user MUST approve contract to transfer the NFT     

- [`listOnMarketplaceWithPremit`]: Users who want to list their NFT for sale with fixed price call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`listOnMarketplace`] internally
 ![add-item-for-sale](https://user-images.githubusercontent.com/10674070/134208929-6499ac39-4bba-40fd-8df2-b7d823a1232f.png)

- [`createAuction`]: Users who want to list their NFT as auction for bidding with/without allowing direct sale.
    - user MUST approve contract to transfer the NFT     
    - Time to live auction duration must be more than 12 hours.
    - if `sellForEnabled` is true, `sellFor` value must be more than zero
    - auction creator MUST specify the insurance amounts for any bidder to bid with considering that it MUST NOT be less that 1 USDT value in STFI. 
- [`createAuctionWithPremit`]: Users who want to list their NFT as auction for bidding with/without allowing direct sale call this function without sending prior transaction to `approve` the marketplace to transfer NFT. This function call`permit` [`eip-2612`] then call [`createAuction`] internally.
![add-item-for-auction](https://user-images.githubusercontent.com/10674070/134208989-881f8568-de01-4c40-a4a8-77fa71bfd780.png)

- [`bid`]: Users who interested in a certain auction, can bid on it by calling this   function.Bidder don't pay / transfer SFTI on bidding. Only when win the auction [`the auction is ended and this bidder is the last one to bid`], bidder pays by calling [`fulfillBid`] OR [`buyNowWithPremit`]
    - user MUST have enough stakes used as insurance; grantee and punishment mechanism for malicious bidder. If the bidder don't pay in the  
    - Bidders can bid as much as they wants , insurance is taken once in the first participation 
    - the bid price MUST be more than the last bid , if this is the first bid, the bid price MUST be more than or equal the minimum bid the auction creator state
    - Users CAN NOT bid on auction after auction time is over
![bid-on-auction](https://user-images.githubusercontent.com/10674070/134209020-0ad23c61-8aa6-4604-94c1-f9e4825baeff.png)

- [`fulfillBid`]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT
    - user MUST approve contract to transfer the STFI tokens , MUST NOT be less than the bid price     
    - Winner bidder can call it within the `fulfillDuration` right after the end of the auction.
    - Winner bider can call it even after the its end as long as the auction reactor has not called dispute. the winner bidder can have chat with the seller  and if the auction creator thinks the winner bidder is not a malicious bidder,  they might agree to wait so we don't want to prevent the scenario where the can see eye to eye. At the end the auction creator wants to buy the NFT and get the price
    - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`] 
  
- [`fulfillBidWithPremit`]: After the end of the Auction, the winner bidder , the last bidder call this function within a certain duration to pay and get the NFT, they call this function without sending prior transaction to `approve` the marketplace to transfer STFI. This function call`permit` [`eip-2612`] then call [`fulfillBid`] internally.
![fulfill-auction](https://user-images.githubusercontent.com/10674070/134209087-44c536f0-40c5-4911-9efe-8de86c0b56be.png)

- [`disputeAuction`]: If the winning bidder didn't pay within the time range stated in te contract `fulfillDuration`, Auction creator calls this function to get the nft back and punish the malicious bidder by taking the insurance (50% goes to the auction staking balance, 50% goes to the platform)
    - Current time  MUST be more than or equal the `disputeTime` for this auction     
    - Only auction Creator can dispute.
    - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, and the auction is approved , auction creator can dispute, if it's not approved yet, auction creator can not.
![dispute-auction](https://user-images.githubusercontent.com/10674070/134209138-a13c7016-6771-4ad5-a9c2-a459eccd2806.png)

- [`buyNow`]: Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can call this function.
    - User MUST approve contract to transfer the STFI token , MUST NOT be less than the price.
   - If the bid price exceed the cap, STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and the transaction can't be proceed unless this deal is approved by Startfi by calling [`approveDeal`]
 

- [`buyNowWithPremit`]:Users who want to buy an NFT from the marketplace whether it's fixed price or auction with `sellForEnabled = true` can this call this function without sending prior transaction to `approve` the marketplace to transfer STFI tokens. This function call`permit` [`eip-2612`] then call [`buyNow`] internally.
![buy-item](https://user-images.githubusercontent.com/10674070/134209164-2c33cb88-42be-488a-9018-a0ebae98c956.png)

- [`deList`]: Users who no longer want to keep their NFT in our marketplace can easly call this function to get their NFT back. Unsuccessful auction creators need to call it as well to get their nft back with no cost as well as  the item added via [`listOnMarketplace`] or [`listOnMarketplaceWithPremit`]  ted in the contract `delistAfter`
    - Only buyers can delist their own items 
    - Auction items can't delisted until the auction ended
![delist-item](https://user-images.githubusercontent.com/10674070/134209183-c2a5b5c1-bbe9-48a2-8518-f08f364ac6fa.png)

- [`migrateEmergency`]: Only when contract is paused, users can safely delist their token with no cost. Startfi team might have to pause the contract to make any update on the protocol terms or in emergency if high risk vulnerability is discovered to protect the users.    
   - Only buyers can delist their own items 
![migrate](https://user-images.githubusercontent.com/10674070/134209244-76e7199e-8599-43b4-99d5-e6f95ec3967b.png)

- [`approveDeal`]:  STartfi is regulated entity in Estonia and regulation compliance is forced in our smart contract, KYC is need first and any purchase transaction with price exceed the cap can't be proceed unless this deal is approved by Startfi by calling this function
- called only by account in owner role
![approve-deal](https://user-images.githubusercontent.com/10674070/134209281-093dce75-4fda-4f2c-8471-b7b1214321e7.png)

- [`freeReserves`]:
users need to stake STFI to list or bid in the marketplace , these tokens needs to set free if the auction is no longer active and user can use these stakes to bid , list or even to withdraw tokens thus, function to free tokens reserved to items of market 
 *  in order to keep track of the on hold stakes.  
 * we store user on-hold stakes in a map `userReserves` 
 * to get user on-hold reserves call  getUserReserved on marketplace
 * to get the number of stakes that not on hold, call  userReserves on marketplace , this function subtract the user stakes in staking contract from the on-hold stakes on marketplace
*This function is greedy, called by user only when s/he wants rather than force the check & updates with every transaction which might be very costly .
   - Only users can free their own reserves 
 ![userActivities](https://user-images.githubusercontent.com/10674070/134209422-5f25278c-3a12-44c9-b016-8eca03bba736.png)

## other scenarios?
==========================



![update-admin-wallet](https://user-images.githubusercontent.com/10674070/134209518-fcebcffd-db40-4d36-a6af-6487ed3397f1.png)
![unpause](https://user-images.githubusercontent.com/10674070/134209554-24d3220a-52eb-4cdf-a7bb-55eab1ecb85d.png)
![set_price](https://user-images.githubusercontent.com/10674070/134209585-1b4d091d-79f8-41fc-b76a-a68de63697d1.png)
![set-cap](https://user-images.githubusercontent.com/10674070/134209605-e3bd0cf0-88dd-487b-93dc-d69504b4ebf6.png)
![pause](https://user-images.githubusercontent.com/10674070/134209643-2f2260cc-4777-4a0e-9295-843546015e99.png)
![mint-nft](https://user-images.githubusercontent.com/10674070/134209706-1c70f6cd-e3c2-41ba-962d-a7d1e3f38e62.png)
![change-marketplace-name](https://user-images.githubusercontent.com/10674070/134209731-361201fc-7ba3-467d-ade5-a8c3cf9d39dc.png)
![change-fulfill-duration](https://user-images.githubusercontent.com/10674070/134209770-83babf4d-8400-4532-b8a9-fcd7d11b570f.png)
![change-fees](https://user-images.githubusercontent.com/10674070/134209801-e1990dd0-83ad-493b-8b0e-21c2166cdebc.png)

![chainge-reputation-contract](https://user-images.githubusercontent.com/10674070/134209904-5bd1b920-446f-44e9-a4a9-96e2eb9e6b33.png)
![add-offer](https://user-images.githubusercontent.com/10674070/134209941-b90d03e1-8c9b-4220-be81-977cfdaf8987.png)

## How to use?
==========================
1. clone `git clone git@github.com:StartFi/core-with-hardhat.git` 
2. run `npm i `
3. to compile , run ` npx hardhat compile`
4. to test , run ` npx hardhat test`
5. To deploy to hardhat, run `npx hardhat deploy`
6. To deploy to certain network . eg. aurora, run `npx hardhat --network testnet_aurora deploy `

