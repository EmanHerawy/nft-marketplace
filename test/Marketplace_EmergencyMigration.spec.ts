import chai, { expect } from 'chai'
import { Contract, constants, utils,BigNumber } from 'ethers'
import { ecsign } from 'ethereumjs-util'

const { MaxUint256 } = constants
import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
/**
 * scenario : StartFi team might need to update the protocol terms or pause the platform if any vulnerability has been found to secure our user,
 * to tackle this  we only allow our service only if the contract is not paused 
 * users can delist their NFT when the contract is paused with no fees  

      # Story 
    * let's say we have 3 auctions  and one list 
    * let's pause the contract and let the users to migrate safely with no lose

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
let price1=1000;
let insurancAmount=10;
let minimumBid=10;
let duration=60*60*15; // 15 hours
let isForSale=false;
let forSalePrice=10000;
const calcFees=(price:number,share:number,base:number):number=>{

  // round decimal to the nearst value
  const _base = base * 100;
 return price*(share/_base);

}

  describe('StartFi marketPlace: let the users to migrate safely with no lose', () => {
   

    const provider = new MockProvider()
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
      reputation.address,
      admin.address,
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
 
    it('create 3 auctions and 1 list go well as long as contract is not paused', async () => {
      await expect(marketPlace.connect(user4).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
        marketPlace,
        'ListOnMarketplace'
      )
      let eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
      let events = await marketPlace.queryFilter(eventFilter)
      listingId1=(events[events.length - 1] as any).args[0]
//2

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
      
 
  
    })
  
  
    // bid 
  
  

    it('users can not migrate if the contract is not paused', async () => {
      await expect(marketPlace.connect(wallet).migrateEmergency(listingId2)).to.be.revertedWith('Pausable: not paused')
 
    })
    it('Users can not list , create auction, buy item or bid as long as the contract is paused ', async () => {
      await marketPlace.connect(admin).pause()
      await expect(marketPlace.connect(user4).listOnMarketplace(NFT.address, mintedNFT[3], price1)).to.be.revertedWith('Pausable: paused')
      await expect(marketPlace.connect(wallet).bid(listingId2, minimumBid+1)).to.be.revertedWith('Pausable: paused')
   await expect(marketPlace.connect(wallet).createAuction(  NFT.address,
    mintedNFT[3],

    minimumBid,
    insurancAmount,
    isForSale,
    forSalePrice,
    duration)).to.be.revertedWith('Pausable: paused')
    await expect(token.connect(wallet).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(wallet).buyNow(listingId1)).to.be.revertedWith('Pausable: paused')


    })
 
    it('go in time where auction is ended, user should not  fulfilled or disputed as long as the contract is paused ', async () => {
      
      const listingDetails = await marketPlace.getListingDetails(listingId2);
       
        await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
        await provider.send('evm_mine',[]);
        const winnerBid= await marketPlace.winnerBid(listingId2)

        await expect(token.connect(user1).approve(marketPlace.address, winnerBid.bidPrice))
        .to.emit(token, 'Approval')
       
        // await expect(marketPlace.connect(user1).fulfillBid(listingId2)).to.be.revertedWith('Pausable: paused')
        // await expect(marketPlace.connect(wallet).disputeAuction(listingId5))
        // .to.be.revertedWith('Pausable: paused')
        await expect(marketPlace.connect(user1).fulfillBid(listingId1)).to.revertedWith(
          'Pausable: paused'
           )
        await expect(marketPlace.connect(wallet).disputeAuction(listingId1)).to.revertedWith(
          'Pausable: paused'
           )
    })
    it('users can migrate their NFT when contract is paused  ', async () => {
    await   expect( marketPlace.connect(user4).migrateEmergency(listingId1))
    .to.emit(marketPlace, 'MigrateEmergency')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user4.address)

  
    })
    it('non owner can not migrate  NFT ', async () => {
      
     await expect(  marketPlace.connect(user4).migrateEmergency(listingId2))
    .to.be.revertedWith('Caller is not the owner')

  
    })

    })
   

 
  
  


 



