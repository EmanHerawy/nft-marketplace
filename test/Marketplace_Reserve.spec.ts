import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'

 import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle
import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
/**
 * scenario : users need to stake STFI to list or bid in the marketplace , these tokens needs to set free if the auction is no longer active and user can use these stakes to bid , list or even to withdraw tokens thus, function to free tokens reserved to items of market 
 *  in order to keep track of the on hold stakes.  
 * we store user on-hold stakes in a map `userReserves` 
 * to get user on-hold reserves call  getUserReserved on marketplace
 * to get the number of stakes that not on hold, call  userReserves on marketplace , this function subtract the user stakes in staking contract from the on-hold stakes on marketplace
      # Story 
    * let's say we have 4 bidders , they bid in 4 auctions 
    *  given that the insurance is equal the insurancAmount, total is 40 for each
    * when  
    * ## user 1 : 40 // 0 on hold
    * bid on auction 1 , status : winner bidder , fulfill  //10
    * bid on auction 2 , status : non winner bidder //10
    * bid on auction 3 , status : non winner bidder //10
    * bid on auction 4 , status : non winner bidder //10
    * ## user 2 : 30 // 10 on hold
    * bid on auction 1 ,  status : non winner bidder //10
    * bid on auction 2 , status : winner bidder , not fulfill ,  passed with no dispute from the auction  //0
    * bid on auction 3 , status : non winner bidder //10
    * bid on auction 4 , status : non winner bidder //10
    * ## user 3 :30 // 10 on hold
    * bid on auction 1 ,  status : non winner bidder //10
    * bid on auction 2 , status : non winner bidder //10
    * bid on auction 2 , status :  winner bidder  not fulfill//0
    * bid on auction 4 , status : non winner bidder //10
    * ## user 4 :30 // 0 on hold
    * bid on auction 1 ,  status : non winner bidder //10
    * bid on auction 2 , status : non winner bidder //10
    * bid on auction 2 , status :  non winner bidder//10
    * bid on auction 4 , status : winner bidder , not fulfill ,  dispute   //0
  * expected result after free reserves 
    * user 1  total ,40 , after freeing reserves 0
    * user 2 total , 40  , after freeing reserves 10
    * user 3 40 , after freeing reserves 10
    * user   40 = 40 , after freeing reserves 0
 * checks 
 *   
  // user can't free already released token
    // user cna't free running auction 
    // user cna't free  auction bidder is not prticipating in 
    // winner biddr can't free his token from free reserve
    // user can free reserves via releaseBatchReserves
    // user can free reserves via releaseListingReserves
 */
chai.use(solidity)

const TEST_AMOUNT = 100000000//expandTo18Decimals(10)
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

 
const royaltyShare=25
const royaltyBase=10
const mintedNFT=[0,1,2,3,4,5,6,7,8,9];
// let marketplaceTokenId1 = mintedNFT[0]
let marketplaceTokenId1:any;
 
let listingId1:any;
let listingId2:any;
let listingId3:any;
let listingId4:any;
let listingId5:any;
let price1=1000;

let insurancAmount=10;
let minimumBid=10;
let duration=60*60*15; // 15 hours
let isForSale=false;
let forSalePrice=10000;

  describe('StartFi marketPlace: let users to free their stakes for auction they lose', () => {
   

    
    const [wallet, user1,user2,user3,user4,admin] = provider.getWallets()
    const loadFixture = createFixtureLoader([wallet])

    let token: Contract
    before(async () => {
      const fixture = await loadFixture(tokenFixture)
      token = fixture.token
      NFT = fixture.NFT
      reputation = fixture.reputation
      stakes = fixture.stakes
  
  
     marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,
       
      admin.address,
 10000,
         50000,
         5
    ])
  
    // add to minter role
    await reputation.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', marketPlace.address)
  
    await stakes.setMarketplace(marketPlace.address)
      // the 3 user need to get balance
  
      await token.transfer(user1.address,TEST_AMOUNT );
      await token.transfer(user2.address,TEST_AMOUNT );
      await token.transfer(user3.address,TEST_AMOUNT );
  
  
      /// issuer mint NFT to test changed balance
      let baseUri = 'http://ipfs.io'
      await NFT.mintWithRoyalty(user4.address, baseUri, royaltyShare, royaltyBase)
      const eventFilter = await NFT.filters.Transfer(null, null )
      const events = await NFT.queryFilter(eventFilter)
      marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
       console.log(marketplaceTokenId1,'marketplaceTokenId1');
      
    })
  
  
  
    it('approve 5 nfts', async () => {
      await expect(NFT.connect(user4).approve(marketPlace.address, marketplaceTokenId1))
        .to.emit(NFT, 'Approval')
        .withArgs(user4.address, marketPlace.address, marketplaceTokenId1)
      expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
   // 2
      await expect(NFT.connect(wallet).approve(marketPlace.address, mintedNFT[0]))
        .to.emit(NFT, 'Approval')
        .withArgs(wallet.address, marketPlace.address, mintedNFT[0])
      expect(await NFT.getApproved(mintedNFT[0])).to.eq(marketPlace.address)
//3
      await expect(NFT.connect(wallet).approve(marketPlace.address, mintedNFT[1]))
        .to.emit(NFT, 'Approval')
        .withArgs(wallet.address, marketPlace.address, mintedNFT[1])
      expect(await NFT.getApproved(mintedNFT[1])).to.eq(marketPlace.address)
      //4
      await expect(NFT.connect(wallet).approve(marketPlace.address, mintedNFT[2]))
        .to.emit(NFT, 'Approval')
        .withArgs(wallet.address, marketPlace.address, mintedNFT[2])
      expect(await NFT.getApproved(mintedNFT[2])).to.eq(marketPlace.address)

      //5
      await expect(NFT.connect(wallet).approve(marketPlace.address, mintedNFT[3]))
        .to.emit(NFT, 'Approval')
        .withArgs(wallet.address, marketPlace.address, mintedNFT[3])
      expect(await NFT.getApproved(mintedNFT[3])).to.eq(marketPlace.address)
    })
 

    it('create 4 auctions and 1 list', async () => {
      await expect(marketPlace.connect(user4).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
        marketPlace,
        'ListOnMarketplace'
      )
      let eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
      let events = await marketPlace.queryFilter(eventFilter)
      listingId1=(events[events.length - 1] as any).args[0]

      await expect(marketPlace.connect(wallet).createAuction(  NFT.address,
        mintedNFT[0],
  
        minimumBid,
        insurancAmount,
        isForSale,
        forSalePrice,
        duration)).to.emit(
        marketPlace,
        'CreateAuction'
      )
        eventFilter = await marketPlace.filters.CreateAuction(null, null)
        events = await marketPlace.queryFilter(eventFilter)
      listingId2=(events[events.length - 1] as any).args[0]

      //3
      await expect(marketPlace.connect(wallet).createAuction(  NFT.address,
        mintedNFT[1],
  
        minimumBid,
        insurancAmount,
        isForSale,
        forSalePrice,
        duration)).to.emit(
        marketPlace,
        'CreateAuction'
      )
        eventFilter = await marketPlace.filters.CreateAuction(null, null)
        events = await marketPlace.queryFilter(eventFilter)
      listingId3=(events[events.length - 1] as any).args[0]
      //4
      await expect(marketPlace.connect(wallet).createAuction(  NFT.address,
        mintedNFT[2],
  
        minimumBid,
        insurancAmount,
        isForSale,
        forSalePrice,
        duration)).to.emit(
        marketPlace,
        'CreateAuction'
      )
        eventFilter = await marketPlace.filters.CreateAuction(null, null)
        events = await marketPlace.queryFilter(eventFilter)
      listingId4=(events[events.length - 1] as any).args[0]
 
  
      //5
      await expect(marketPlace.connect(wallet).createAuction(  NFT.address,
        mintedNFT[3],
  
        minimumBid,
        insurancAmount,
        isForSale,
        forSalePrice,
        duration)).to.emit(
        marketPlace,
        'CreateAuction'
      )
        eventFilter = await marketPlace.filters.CreateAuction(null, null)
        events = await marketPlace.queryFilter(eventFilter)
      listingId5=(events[events.length - 1] as any).args[0]
    })
  
  
    // bid 
  
  

    it('deposit stakes', async () => {
      const stakeAmount = insurancAmount;
      
      await expect(token.approve(stakes.address, TEST_AMOUNT))// needs stakes
        .to.emit(token, 'Approval')
        .withArgs(wallet.address, stakes.address, TEST_AMOUNT)
      expect(await token.allowance(wallet.address, stakes.address)).to.eq(TEST_AMOUNT)
  
      await stakes.deposit(user1.address, stakeAmount*4)
      let reserves = await stakes.getReserves(user1.address)
      expect(reserves.toNumber()).to.eq(stakeAmount*4)
  
      await stakes.deposit(user2.address, stakeAmount*4)
        reserves = await stakes.getReserves(user2.address)
      expect(reserves.toNumber()).to.eq(stakeAmount*4)
  
      await stakes.deposit(user3.address, stakeAmount*4)
        reserves = await stakes.getReserves(user3.address)
      expect(reserves.toNumber()).to.eq(stakeAmount*4)
  
      await stakes.deposit(user4.address, stakeAmount*4)
        reserves = await stakes.getReserves(user4.address)
      expect(reserves.toNumber()).to.eq(stakeAmount*4 )
  

    })

  
   
    it('Should  bid on item with price equal or more than the mini bid price', async () => {
      // auction 1
      await expect(marketPlace.connect(user1).bid(listingId2, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user2).bid(listingId2, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user3).bid(listingId2, minimumBid+100)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user4).bid(listingId2, minimumBid+200)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user1).bid(listingId2, minimumBid+1000)).to.emit(marketPlace, 'BidOnAuction')


      // auction 2
      await expect(marketPlace.connect(user1).bid(listingId3, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user2).bid(listingId3, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user3).bid(listingId3, minimumBid+100)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user4).bid(listingId3, minimumBid+200)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user2).bid(listingId3, minimumBid+1000)).to.emit(marketPlace, 'BidOnAuction')

      // auction 
      await expect(marketPlace.connect(user1).bid(listingId4, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user2).bid(listingId4, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user3).bid(listingId4, minimumBid+100)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user4).bid(listingId4, minimumBid+200)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user3).bid(listingId4, minimumBid+1000)).to.emit(marketPlace, 'BidOnAuction')
      // auction 4
      await expect(marketPlace.connect(user1).bid(listingId5, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user2).bid(listingId5, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user3).bid(listingId5, minimumBid+100)).to.emit(marketPlace, 'BidOnAuction')
      await expect(marketPlace.connect(user4).bid(listingId5, minimumBid+200)).to.emit(marketPlace, 'BidOnAuction')
    
  
    })

        it('users  can not free reserves in active auctions  ', async () => {
      await expect(marketPlace.releaseListingReserves(listingId2,user2.address)).to.revertedWith ('Can not release stakes for running auction')
        })
    
    
    it('go in time where auctions  ended, auction 1  is fulfilled and 4 is disputed, the rest no actions ', async () => {
      const listingDetails = await marketPlace.getListingDetails(listingId2);
       
        await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
        await provider.send('evm_mine',[]);
        const winnerBid= await marketPlace.winnerBid(listingId2)

        await expect(token.connect(user1).approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
       
        await expect(marketPlace.connect(user1).fulfillBid(listingId2)).to.emit(marketPlace,  'FulfillBid')
        await expect(marketPlace.connect(wallet).disputeAuction(listingId5))
    .to.emit(marketPlace, 'DisputeAuction')
  
    })
 
      it('users  can not free reserves in auction already released by fulfilling auction  ', async () => {
      await expect(marketPlace.releaseListingReserves(listingId2,user1.address)).to.revertedWith ('Already released')
        })
      it('users  can not free reserves in auction s/he win, they have to fulfill  ', async () => {
      await expect(marketPlace.releaseListingReserves(listingId3,user2.address)).to.revertedWith ('Winner bidder can  only  release stakes by fulfilling the auction')
        })
    
    
    it('user 1 can call releaseBatchReserves and reserves should be after freeing reserves =0', async () => {
      await expect(marketPlace.releaseListingReserves(listingId3,user1.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId4,user1.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId5,user1.address)).to.emit(marketPlace, 'UserReservesRelease')

   
      const expectedReserves= BigNumber.from(0)
      expect(await marketPlace.getUserReserved(user1.address)).to.eq(expectedReserves)
       // check balance 
    })
    it('user 2 reserves should be after freeing reserves =10', async () => {
     
      await expect(marketPlace.releaseListingReserves(listingId2,user2.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId4,user2.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId5,user2.address)).to.emit(marketPlace, 'UserReservesRelease')
      const expectedReserves= BigNumber.from(10)
      expect(await marketPlace.getUserReserved(user2.address)).to.eq(expectedReserves)
       // check balance 
    })
    it('user 3 reserves should be after freeing reserves =10', async () => {
     
      await expect(marketPlace.releaseListingReserves(listingId3,user3.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves( listingId2 ,user3.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves( listingId5,user3.address)).to.emit(marketPlace, 'UserReservesRelease')
      const expectedReserves= BigNumber.from(10)
      expect(await marketPlace.getUserReserved(user3.address)).to.eq(expectedReserves)
       // check balance 
    })
    it('user 4 reserves should be after freeing reserves =0', async () => {
     
      await expect(marketPlace.releaseListingReserves(listingId2,user4.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId3,user4.address)).to.emit(marketPlace, 'UserReservesRelease')
      await expect(marketPlace.releaseListingReserves(listingId4,user4.address)).to.emit(marketPlace, 'UserReservesRelease')
      const expectedReserves= BigNumber.from(0)
      expect(await marketPlace.getUserReserved(user4.address)).to.eq(expectedReserves)
       // check balance 
    })

       it('user  can not free reserves in auction s/he is not participating on  ', async () => {
      await expect(marketPlace.connect(user1).releaseListingReserves(listingId1,admin.address)).to.revertedWith ('Bidder is not participating in this auction')
    })
  
  })


