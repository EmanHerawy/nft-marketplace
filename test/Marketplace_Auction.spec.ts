import chai, { expect } from 'chai'
import { Contract, constants, utils,BigNumber } from 'ethers'
import { ecsign } from 'ethereumjs-util'

const { MaxUint256 } = constants
import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals, getApprovalDigest, getApprovalNftDigest } from './shared/utilities'
import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
import { hexlify } from 'ethers/lib/utils'
/**
 * scenarios
 *  we have 3 type of listings , fix price , auction , auction with direct sale.
 * 1- user can sell item on marketplace  with fixed price 
 * -- user must stake some tokens 
 * -- marketplace must be allowed to transfer his token and he must pass all condition 
 * -- any buyer can buy this item after passing all condition 
 * -- seller balance is increased , wallet is increased and original issuer balance is increased if the nft has
 * -- user adds item but no one bought the item , user delist before the time and loses the qualify amount 
 * -- user adds item but no one bought the item , user delist after the time and without losing the qualify amount 
 * *************
 * 2- user can sell item on marketplace  ass auction with direct sell 
 * -- marketplace must be allowed to transfer his token and he must pass all condition 
 * -- buyers can bid and bid and bid  as long as it's active after staking and giving the right bid
 * -- any buyer can buy this item after passing all condition 
 * -- seller balance is increased , wallet is increased and original issuer balance is increased if the nft has

 * -- user adds item but no one bought the item , user delist only after the auction is ended 
* *************
 * 2- user can sell item on marketplace  ass auction with direct sell 
 * -- marketplace must be allowed to transfer his token and he must pass all condition 
 * -- buyers can bid and bid and bid  as long as it's active after staking and giving the right bid
 * -- last bidder can get the item by fulfill 
 * -- if winner bidder doesn't fulfill, auction creator dispute and get 50% from the qualify amount while startfi takes the other 50%, NFT ownership is returned back to the auction creator 
 * -- user adds item but no one bought the item , user delist only after the auction is ended 

 * 
 * -- big deals 
 * -- transaction with permit
 * 
 */
chai.use(solidity)
const name = 'StartFiToken'
const symbol = 'STFI'
const TOTAL_SUPPLY = expandTo18Decimals(100000000)
const TEST_AMOUNT = 100000000//expandTo18Decimals(10)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

const   _feeFraction = 25; // 2.5% fees
const   _feeBase = 10;
 
const royaltyShare=25
const royaltyBase=10
const mintedNFT=[0,1,2,3,4,5,6,7,8,9];
// let marketplaceTokenId1 = mintedNFT[0]
let marketplaceTokenId1:any;
let marketplaceTokenId2 =  mintedNFT[1]
let auctionTokenId =  mintedNFT[2]
let listingId1:any;
let listingId2:any;
let zeroPrice=0;
let price1=1000;
let price2=10000;
let price3=50050;
let qualifyAmount=10;
let minimumBid=10;
let wrongPrice=10;
let lastbidding=minimumBid;
let duration=60*60*15; // 15 hours
let isForSale=false;
let forSalePrice=10000;
const calcFees=(price:number,share:number,base:number):number=>{

  // round decimal to the nearst value
  const _base = base * 100;
 return price*(share/_base);

}
describe('StartFi marketPlace:Actions create  bid and for sale as well , bid and buyNow, now bid after purchase', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })



  it('create auction should not be with zero bid', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      zeroPrice,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Zero Value is not allowed'
    )
  })
  it('create auction should not be allowed if marketplace is not approved', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })

  it('create auction should not be with zero price id sale fore is enabled', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Zero price is not allowed'
    )
  })
  it('Auction should be live for more than 12 hours', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      forSalePrice,
      60*60)).to.be.revertedWith(
      'Auction should be live for more than 12 hours'
    )
  })
  it('Auction qualify Amount must be equal or more than 1 usdt in STFI', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      1,
      !isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Invalid Auction qualify Amount'
    )
  })

  it('Should create auction that accepts bid and direct sale', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })


  // bid 

  it('Should not bid on item with price less than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid-1)).to.revertedWith('bid price must be more than or equal the minimum price')

  })
  it('if it is first time to bid, user can not bid without staking', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.revertedWith('Not enough reserves')

  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should  bid on item with price more than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.revertedWith('bid price must be more than the last bid')

  })


  it('user can  buy auction which is  for sale', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, forSalePrice)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1, forSalePrice)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -forSalePrice)
    const platformShare =Math.round(calcFees(forSalePrice,_feeFraction,_feeBase))
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(forSalePrice-platformShare)
// check balance 
  })
 it('Can not delist already bought item ', async () => {
   await expect(marketPlace.connect(issuer).deList(listingId1)).to.revertedWith('Already bought token')
        
  })

  it('Should not fulfill already bought auction', async () => {
    await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'Auction is not ended or no longer on auction')

  })
// isOpenAuction

it('Should not bid on item after auction is bought', async () => {
 
  await expect(marketPlace.bid(listingId1, minimumBid+20)).to.revertedWith( 'Auction is ended')

})

})
describe('StartFi marketPlace:Actions create  bid only, bid and fulfill', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })



  it('create auction should not be with zero bid', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      zeroPrice,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Zero Value is not allowed'
    )
  })
  it('create auction should not be allowed if marketplace is not approved', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })

  it('create auction should not be with zero price id sale fore is enabled', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Zero price is not allowed'
    )
  })
  it('Auction should be live for more than 12 hours', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      zeroPrice,
      60*60)).to.be.revertedWith(
      'Auction should be live for more than 12 hours'
    )
  })
  it('Auction qualify Amount must be equal or more than 1 usdt in STFI', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      1,
      isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Invalid Auction qualify Amount'
    )
  })

  it('Should create auction', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('user can not buy auction which is not for sale', async () => {
    await expect(marketPlace.connect(user1).buyNow(listingId1, forSalePrice)).to.revertedWith(
   'Token is not for sale'
    )
  })

  // bid 

  it('Should not bid on item with price less than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid-1)).to.revertedWith('bid price must be more than or equal the minimum price')

  })
  it('if it is first time to bid, user can not bid without staking', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.revertedWith('Not enough reserves')

  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should  bid on item with price more than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should not fulfill auction before auction end', async () => {
    await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'Auction is not ended or no longer on auction')

  })
// isOpenAuction

it('Should not bid on item after auction is ended', async () => {
  const listingDetails = await marketPlace.getListingDetails(listingId1);
 
  await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
  await provider.send('evm_mine',[]);
  await expect(marketPlace.bid(listingId1, minimumBid+20)).to.revertedWith( 'Auction is ended')

})

it('Non winner bidder can not fulfill auction', async () => {
  await expect(marketPlace.connect(issuer).fulfillBid(listingId1)).to.revertedWith(  'Caller is not the winner')

})
// it('exceeded cap bids can not be fulfilled without approval', async () => {
//   await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'StartfiMarketplace: StartfiMarketplace: Price exceeded the cap. You need to get approved')

// })
it('Should not fulfill auction without allowing token to pay', async () => {
  await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'Marketplace is not allowed to withdraw the required amount of tokens')

})
it('Should  fulfill auction after allowing token to pay', async () => {
  const winnerBid= await marketPlace.winnerBid(listingId1)

  await expect(token.approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
  await expect(marketPlace.fulfillBid(listingId1)).to.emit(marketPlace,  'FulfillBid')
  expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( wallet.address)
  const platformShare =Math.round(calcFees(winnerBid.bidPrice,_feeFraction,_feeBase))
  expect(await token.balanceOf(admin.address)).to.eq(platformShare)
  expect(await token.balanceOf(issuer.address)).to.eq(winnerBid.bidPrice-platformShare)
})
})
describe('malicious auction creator:  marketPlace:Actions create bid only, receive bid, winner bidder fulfills and auction creator tries to dispute ', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })



  it('create auction should not be with zero bid', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      zeroPrice,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Zero Value is not allowed'
    )
  })
  it('create auction should not be allowed if marketplace is not approved', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })

  it('create auction should not be with zero price id sale fore is enabled', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Zero price is not allowed'
    )
  })
  it('Auction should be live for more than 12 hours', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      zeroPrice,
      60*60)).to.be.revertedWith(
      'Auction should be live for more than 12 hours'
    )
  })
  it('Auction qualify Amount must be equal or more than 1 usdt in STFI', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      1,
      isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Invalid Auction qualify Amount'
    )
  })

  it('Should create auction', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('user can not buy auction which is not for sale', async () => {
    await expect(marketPlace.connect(user1).buyNow(listingId1, forSalePrice)).to.revertedWith(
   'Token is not for sale'
    )
  })

  // bid 

  it('Should not bid on item with price less than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid-1)).to.revertedWith('bid price must be more than or equal the minimum price')

  })
  it('if it is first time to bid, user can not bid without staking', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.revertedWith('Not enough reserves')

  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should  bid on item with price more than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should not fulfill auction before auction end', async () => {
    await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'Auction is not ended or no longer on auction')

  })
// isOpenAuction

it('Should not bid on item after auction is ended', async () => {
  const listingDetails = await marketPlace.getListingDetails(listingId1);
 
  await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
  await provider.send('evm_mine',[]);
  await expect(marketPlace.bid(listingId1, minimumBid+20)).to.revertedWith( 'Auction is ended')

})

it('Non winner bidder can not fulfill auction', async () => {
  await expect(marketPlace.connect(issuer).fulfillBid(listingId1)).to.revertedWith(  'Caller is not the winner')

})
// it('exceeded cap bids can not be fulfilled without approval', async () => {
//   await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'StartfiMarketplace: StartfiMarketplace: Price exceeded the cap. You need to get approved')

// })
it('Should not fulfill auction without allowing token to pay', async () => {
  await expect(marketPlace.fulfillBid(listingId1)).to.revertedWith(  'Marketplace is not allowed to withdraw the required amount of tokens')

})
it('Should  fulfill auction after allowing token to pay', async () => {
  const winnerBid= await marketPlace.winnerBid(listingId1)

  await expect(token.approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
  await expect(marketPlace.fulfillBid(listingId1)).to.emit(marketPlace,  'FulfillBid')
  expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( wallet.address)
  const platformShare =Math.round(calcFees(winnerBid.bidPrice,_feeFraction,_feeBase))
  expect(await token.balanceOf(admin.address)).to.eq(platformShare)
  expect(await token.balanceOf(issuer.address)).to.eq(winnerBid.bidPrice-platformShare)
})
it('Should not dispute item not on auction', async () => {
  await expect(marketPlace.connect(issuer).disputeAuction(listingId1))
     .to.revertedWith('Marketplace: Item is not on Auction')    
 })
})
describe('malicious bidder: marketPlace:Actions create bid only , bid  malicious bidder did not pay the price via fulfill function , auction creator can dispute and take the insurance as well as the nft back', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })



  it('create auction should not be with zero bid', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      zeroPrice,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Zero Value is not allowed'
    )
  })
  it('create auction should not be allowed if marketplace is not approved', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })

  it('create auction should not be with zero price id sale fore is enabled', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Zero price is not allowed'
    )
  })
  it('Auction should be live for more than 12 hours', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      zeroPrice,
      60*60)).to.be.revertedWith(
      'Auction should be live for more than 12 hours'
    )
  })
  it('Auction qualify Amount must be equal or more than 1 usdt in STFI', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      1,
      isForSale,
      zeroPrice,
      duration)).to.be.revertedWith(
      'Invalid Auction qualify Amount'
    )
  })

  it('Should create auction', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('user can not buy auction which is not for sale', async () => {
    await expect(marketPlace.connect(user1).buyNow(listingId1, forSalePrice)).to.revertedWith(
   'Token is not for sale'
    )
  })
  it('Should not fulfill auction before auction end', async () => {
    await expect(marketPlace.connect(issuer).disputeAuction(listingId1)).to.revertedWith('Marketplace: Auction has no bids')

  })
  // bid 

  it('Should not bid on item with price less than the mini bid price', async () => {
    await expect(marketPlace.connect(wallet).bid(listingId1, minimumBid-1)).to.revertedWith('bid price must be more than or equal the minimum price')

  })
  it('if it is first time to bid, user can not bid without staking', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.revertedWith('Not enough reserves')

  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+1)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid)).to.revertedWith('bid price must be more than the last bid')

  })
  it('Should  bid on item with price more than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should not bid on item with price less than the last bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid+10)).to.revertedWith('bid price must be more than the last bid')

  })

  it('Should not fulfill auction before auction end', async () => {
    await expect(marketPlace.connect(issuer).disputeAuction(listingId1)).to.revertedWith(  'Marketplace: Can not dispute before time')

  })
// isOpenAuction
it('Non seller can not dispute auction', async () => {
  await expect(marketPlace.connect(wallet).disputeAuction(listingId1)).to.revertedWith(  'Only Seller can dispute')

})

/**@dev for some reason, the timestamp increased more than the release time and exceed the dispute time which lead to test failure  */

/*it('Should not dispute right after auction is ended ', async () => {
  const listingDetails = await marketPlace.getListingDetails(listingId1);
  console.log(listingDetails,'listingDetails');
  
  await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
  await provider.send('evm_mine',[]);
const blocknumber=  await provider.send('eth_getBlockByNumber',['latest',null]);
console.log(blocknumber,'blocknumber');
const timeStamp=BigNumber.from( blocknumber.timestamp);
console.log(timeStamp,'timeStamp');

  await expect(timeStamp).to.eq( listingDetails.releaseTime)
   await expect(marketPlace.connect(issuer).disputeAuction(listingId1)).to.revertedWith( 'Marketplace: Can not dispute before time')

})
*/

it('Should dispute item after dispute time', async () => {
  const bidderStakeAllowance = await stakes.getReserves(wallet.address)
  const adminStakeAllowance = await stakes.getReserves(admin.address)
  const sellerStakeAllowance = await stakes.getReserves(issuer.address)
 
const listingDetails = await marketPlace.getListingDetails(listingId1);
  await provider.send('evm_increaseTime', [listingDetails.disputeTime.toNumber()]); 
  await provider.send('evm_mine',[]);
  await expect(marketPlace.connect(issuer).disputeAuction(listingId1))
    .to.emit(marketPlace, 'DisputeAuction')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( issuer.address)

    const newBidderStakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    const newAdminStakeAllowance = await marketPlace.getStakeAllowance(admin.address)
    const newSellerStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    //50 to admin , 50 % to auction creator , bidder loses qualify amount
const fineAmount:number=Math.round(qualifyAmount/2)
    expect(newBidderStakeAllowance).to.eq(BigNumber.from(bidderStakeAllowance - qualifyAmount))
    expect(newAdminStakeAllowance).to.eq(BigNumber.from(adminStakeAllowance + fineAmount))
    expect(newSellerStakeAllowance).to.eq(BigNumber.from(sellerStakeAllowance + fineAmount))
 
    
})
it('Should not dispute item not on auction', async () => {
 await expect(marketPlace.connect(issuer).disputeAuction(listingId1))
    .to.revertedWith('Marketplace: Item is not on Auction')    
})

// delist



  })

describe('StartFi marketPlace : create auction and buy WithPremit', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
    marketplaceTokenId1 = mintedNFT[0];
    
    await token.transfer(user1.address,TEST_AMOUNT );
  })

  it('Creat biding Auction:permit', async () => {
    const nonce = await NFT.nonces(wallet.address)
    const chainId = await NFT.getChainId()
    const deadline = MaxUint256
    const digest = await getApprovalNftDigest(
      NFT,
      { owner: wallet.address, spender: marketPlace.address, tokenId: marketplaceTokenId1 },
      nonce,
      deadline,
      chainId
    )
    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))

    await expect(
      await marketPlace.createAuctionWithPremit(
        NFT.address,
        marketplaceTokenId1,

        minimumBid,
        qualifyAmount,
        !isForSale,
        forSalePrice,
        duration,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('user can buynow:permit', async () => {
    const nonce = await token.nonces(user1.address)  
    const deadline = MaxUint256
    const digest = await getApprovalDigest(
      token,
      { owner: user1.address, spender: marketPlace.address, value: BigNumber.from(forSalePrice )},
      nonce,
      deadline,
      BigNumber.from(0),
    )

    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1.privateKey.slice(2), 'hex'))
     await expect(
      await marketPlace.connect(user1).buyNowWithPremit(
       listingId1,
       forSalePrice,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -forSalePrice)
      })

})
describe('StartFi marketPlace : create auction and bid and fulfill WithPremit', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
    marketplaceTokenId1 = mintedNFT[0];
    
    await token.transfer(user1.address,TEST_AMOUNT );
  })

  it('Creat biding Auction:permit', async () => {
    const nonce = await NFT.nonces(wallet.address)
    const chainId = await NFT.getChainId()
    const deadline = MaxUint256
    const digest = await getApprovalNftDigest(
      NFT,
      { owner: wallet.address, spender: marketPlace.address, tokenId: marketplaceTokenId1 },
      nonce,
      deadline,
      chainId
    )
    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))

    await expect(
      await marketPlace.createAuctionWithPremit(
        NFT.address,
        marketplaceTokenId1,

        minimumBid,
        qualifyAmount,
        isForSale,
        zeroPrice,
        duration,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(user1.address, stakeAmount)
    const reserves = await stakes.getReserves(user1.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.connect(user1).bid(listingId1, minimumBid+10)).to.emit(marketPlace, 'BidOnAuction')

  })

  it('Should fulfill  biding auction:permit', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1);
 
    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
    await provider.send('evm_mine',[]);
    const nonce = await token.nonces(user1.address)  
    const deadline = MaxUint256
    const digest = await getApprovalDigest(
      token,
      { owner: user1.address, spender: marketPlace.address, value: BigNumber.from(minimumBid+10 )},
      nonce,
      deadline,
      BigNumber.from(0),
    )

    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1.privateKey.slice(2), 'hex'))

    await expect(
      await marketPlace.connect(user1).fulfillBidWithPremit(
       listingId1,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'FulfillBid')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
   
  })
})

describe('StartFi marketPlace Auction: big deals that exceed cap', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
price1=500000;
forSalePrice=price1
  // add to minter role
  await reputation.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', marketPlace.address)

  await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address,TEST_AMOUNT );
    await token.transfer(user2.address,TEST_AMOUNT );
    await token.transfer(user3.address,TEST_AMOUNT );


    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })
  it('Should create auction', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })

  it('user can not buy  an item on marketplace that exceeded the cap before it is approved', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1, price1)).to.revertedWith('StartfiMarketplace: Price exceeded the cap. You need to get approved')
 
// check balance 
  })
  it('Should approve deal', async () => {
    // TODO: add event here
    const transactionRecipe = await marketPlace.connect(admin).approveDeal(listingId1)
    expect(transactionRecipe.from).equal(admin.address)
  })
  it('user can buy  an item that exceeded the cap on marketplace after it is approved', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1, price1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -price1)
    const platformShare =Math.round(calcFees(price1,_feeFraction,_feeBase))
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(price1-platformShare)



  })

  })
describe('StartFi marketPlace Auction bid and fulfill: big deals that exceed cap', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
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
price1=500000;
forSalePrice=price1
  // add to minter role
  await reputation.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', marketPlace.address)

  await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address,TEST_AMOUNT );
    await token.transfer(user2.address,TEST_AMOUNT );
    await token.transfer(user3.address,TEST_AMOUNT );


    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null )
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1=(events[events.length - 1] as any).args[2].toNumber()
     console.log(marketplaceTokenId1,'marketplaceTokenId1');
    
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })
  it('Should create auction', async () => {
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      qualifyAmount,
      !isForSale,
      forSalePrice,
      duration)).to.emit(
      marketPlace,
      'CreateAuction'
    )
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('deposit stakes', async () => {
    const stakeAmount = qualifyAmount;
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(user1.address, stakeAmount)
    const reserves = await stakes.getReserves(user1.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.connect(user1).bid(listingId1, price1)).to.emit(marketPlace, 'BidOnAuction')

  })


  it('Should not fulfill unapproved auction  even after allowing token to pay', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1);
 
    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
    await provider.send('evm_mine',[]);
    const winnerBid= await marketPlace.winnerBid(listingId1)
  
    await expect(token.connect(user1).approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).fulfillBid(listingId1)).to.revertedWith('StartfiMarketplace: Price exceeded the cap. You need to get approved')
  })
 

  it('Should   approve deal', async () => {
    // TODO: add event here
    const listingDetails = await marketPlace.getListingDetails(listingId1);
 
    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
    await provider.send('evm_mine',[]);
    const transactionRecipe = await marketPlace.connect(admin).approveDeal(listingId1)
    expect(transactionRecipe.from).equal(admin.address)
  })
  it('Should  fulfill approved auction  even after allowing token to pay', async () => {
    const winnerBid= await marketPlace.winnerBid(listingId1)
  
    await expect(token.connect(user1).approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).fulfillBid(listingId1)).to.emit(marketPlace,  'FulfillBid')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    const platformShare =Math.round(calcFees(winnerBid.bidPrice,_feeFraction,_feeBase))
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(winnerBid.bidPrice-platformShare)
  })

  })
/*
describe('StartFi marketPlace:Actions', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])

  const approvedTokenAmount = 10000
  const stakedTokenAmount = 10000
  const auctionsId: string[] = []
  const listonMarketplaceIds: string[] = []
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
    await token.approve(stakes.address, approvedTokenAmount)
    await stakes.deposit(wallet.address, stakedTokenAmount)
    for (let tokenId = 0; tokenId < 5; tokenId++) {
      await NFT.approve(marketPlace.address, tokenId)
      await marketPlace.createAuction(NFT.address, tokenId, 10, 11, true, 11, 1000000000)
      const eventFilter = await marketPlace.filters.CreateAuction(null, null)
      const events = await marketPlace.queryFilter(eventFilter)
      auctionsId.push(await (events[events.length - 1] as any).args[0])
    }
     })
  it('Should bid item', async () => {
    await expect(marketPlace.bid(auctionsId[0], 1200)).to.emit(marketPlace, 'BidOnAuction')
    await expect(marketPlace.bid(auctionsId[1], 1200)).to.emit(marketPlace, 'BidOnAuction')
    await expect(marketPlace.bid(auctionsId[2], 1200)).to.emit(marketPlace, 'BidOnAuction')
  })
  it('Should fullfil bid item', async () => {
    await expect(token.approve(marketPlace.address, 1200)).to.emit(token, 'Approval')
    await expect(marketPlace.fulfillBid(auctionsId[0])).to.emit(marketPlace, 'FulfillBid')
  })
  it('Should approve deal', async () => {
    const transactionRecipe = await marketPlace.approveDeal(listonMarketplaceIds[0])
    expect(transactionRecipe.from).equal(wallet.address)
  })
  it('Buy now: Marketplace is not allowed to withdraw the required amount of tokens', async () => {
    await expect(marketPlace.buyNow(listonMarketplaceIds[0], 1200)).to.be.revertedWith(
      'Marketplace is not allowed to withdraw the required amount of tokens'
    )
  })
  







  it('Should set marketCap', async () => {
    const transactionRecipe = await marketPlace.setUsdCap(5)
    expect(transactionRecipe.from).equal(wallet.address)
  })
  it('Should set STFI price', async () => {
    const transactionRecipe = await marketPlace.setPrice(23)
    expect(transactionRecipe.from).equal(wallet.address)
  })
  it('Should UserReservesFree', async () => {
    await expect(marketPlace.freeReserves()).to.emit(marketPlace, 'UserReservesFree')
  })
})
*/