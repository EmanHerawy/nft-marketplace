import chai, { expect } from 'chai'
import { Contract,BigNumber } from 'ethers'

import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals } from './shared/utilities'
import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
import { hexlify } from 'ethers/lib/utils'
/**
 * scenarios
 *  we might have some celebrities or big names who come to our platform though agreement, those users might need different terms and conditions and to enforce the agreement via smart contract we store them the contract and apply them in their deals  .
 *
 * 
 */
chai.use(solidity)
const TEST_AMOUNT = 100000000//expandTo18Decimals(10)
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

const   _feeFraction = 25; // 2.5% fees
const   _feeBase = 10;
 
const   listqualifyPercentage = 10;
 
const   listqualifyPercentageBase = 10;
const royaltyShare=25
const royaltyBase=10
let marketplaceTokenId1:string;
let listingId1:string;
let listingId2:string;
let price1=1000;
let insuranceAmount=10;
let minimumBid=10;
let duration=60*60*15; // 15 hours
let isForSale=false;
let forSalePrice=10000;
const calcFees=(price:number,share:number,base:number):number=>{

  // round decimal to the nearst value
  const _base = base * 100;
 return price*(share/_base);

}
describe('StartFi marketPlace Sprciall offers : special Offers with fixed prices', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
 
    _listqualifyPercentage:20,
 
    _listqualifyPercentageBase:10,
    _feeBase:10
}]
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

  it('non admin can not add special offer ', async () => {
    await expect(marketPlace.addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
   
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
    
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer allowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.revertedWith('StartFiMarketPlaceSpecialOffer: Already exisit')
  })
  it('special offer cannot use the ordinary terms for his listing', async () => {
    await expect(marketPlace.listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Not enough reserves'
    )
    const stakeAmount =  calcFees(price1,listqualifyPercentage,listqualifyPercentageBase);
    console.log(stakeAmount,'stakeAmount');
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(issuer.address, stakeAmount)
    const reserves = await stakes.getReserves(issuer.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  
  await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
    'Not enough reserves'
  )
  })

  it('Special offer Should list on marketplace only using the deal terms', async () => {
    const oldReserves = await stakes.getReserves(issuer.address)

    const stakeAmount =  calcFees(price1, offers[0]. _listqualifyPercentage, offers[0]. _listqualifyPercentageBase);
    console.log(stakeAmount,'stakeAmount');
    const stakeToIncrease = stakeAmount-oldReserves.toNumber();
    await expect(token.approve(stakes.address, stakeToIncrease))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeToIncrease)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeToIncrease)

    await stakes.deposit(issuer.address, stakeToIncrease)
    const reserves = await stakes.getReserves(issuer.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
 
 
  it('user can buy  an item on marketplace  using the offer terms', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -price1)
    const platformShare =Math.round(calcFees(price1,offers[0]. _fee,offers[0]. _feeBase))
    const platformWrongShare =Math.round(calcFees(price1,_feeFraction,_feeBase))
    console.log(platformShare,platformWrongShare,'shares');
    
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(price1-platformShare)
    expect(await token.balanceOf(admin.address)).to.not.eq(platformWrongShare)
    expect(await token.balanceOf(issuer.address)).to.not.eq(price1-platformWrongShare)
// check balance 
// check balance 
  })
  
  })
describe('StartFi marketPlace : special Offers with fixed prices issuer deList with special terms', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
 
    _listqualifyPercentage:20,
 
    _listqualifyPercentageBase:10,
    _feeBase:10
}]
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

  it('non admin can not add special offer ', async () => {
    await expect(marketPlace.addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
   
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
    
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer allowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.revertedWith('StartFiMarketPlaceSpecialOffer: Already exisit')
  })
  it('special offer cannot use the ordinary terms for his listing', async () => {
    await expect(marketPlace.listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Not enough reserves'
    )
    const stakeAmount =  calcFees(price1,listqualifyPercentage,listqualifyPercentageBase);
    console.log(stakeAmount,'stakeAmount');
    
    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(issuer.address, stakeAmount)
    const reserves = await stakes.getReserves(issuer.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  
  await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
    'Not enough reserves'
  )
  })

  it('Special offer Should list on marketplace only using the deal terms', async () => {
    const oldReserves = await stakes.getReserves(issuer.address)

    const stakeAmount =  calcFees(price1, offers[0]. _listqualifyPercentage, offers[0]. _listqualifyPercentageBase);
    const stakeToIncrease = stakeAmount-oldReserves.toNumber();
    await expect(token.approve(stakes.address, stakeToIncrease))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeToIncrease)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeToIncrease)

    await stakes.deposit(issuer.address, stakeToIncrease)
    const reserves = await stakes.getReserves(issuer.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
 
 // delist and lost reserves
it('Should delist item and lose stakes', async () => {



  await expect(marketPlace.connect(issuer).deList(listingId1))
    .to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( issuer.address)

    const newStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(newStakeAllowance.toNumber()).to.eq(0)
    const eventFilter2 = await marketPlace.filters.DeListOffMarketplace(null, null )
    const events2 = await marketPlace.queryFilter(eventFilter2)
    const fineAmount=(events2[events2.length - 1] as any).args[4].toNumber()
    const remaining=(events2[events2.length - 1] as any).args[5].toNumber()
     console.log(fineAmount,remaining,'events2 marketplaceTokenId1');
    
})
it('Can not delist already de listed item ', async () => {
  await expect(marketPlace.connect(issuer).deList(listingId1)).to.revertedWith('Already bought or canceled token')
       
 })
it('non owner can not delist ', async () => {
  const stakeAmount =  calcFees(price1, offers[0]. _listqualifyPercentage, offers[0]. _listqualifyPercentageBase);
  
  await expect(token.approve(stakes.address, stakeAmount))
    .to.emit(token, 'Approval')
    .withArgs(wallet.address, stakes.address, stakeAmount)
  expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

  await stakes.deposit(issuer.address, stakeAmount)
  const reserves = await stakes.getReserves(issuer.address)
  expect(reserves.toNumber()).to.eq(stakeAmount)

  const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
  expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
    marketPlace,
    'ListOnMarketplace'
  )
  const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
  const events = await marketPlace.queryFilter(eventFilter)
    listingId2=(events[events.length - 1] as any).args[0]
  await expect(marketPlace.connect(wallet).deList(listingId2)).to.revertedWith('Caller is not the owner')
      
})
// delist
it('Should delist item without losing stakes', async () => {


  const stakeAllowance = await stakes.getReserves(issuer.address)
const listingDetails = await marketPlace.getListingDetails(listingId2);

  await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
  await provider.send('evm_mine',[]);
  await expect(marketPlace.connect(issuer).deList(listingId2))
    .to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( issuer.address)

    const newStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    
    expect(newStakeAllowance.toNumber()).to.eq(stakeAllowance)
 
    
})

  
  })
describe('StartFi marketPlace : special Offers with Auction bid and buy', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
 
    _listqualifyPercentage:20,
 
    _listqualifyPercentageBase:10,
    _feeBase:10
}]
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

  it('non admin can not add special offer ', async () => {
    await expect(marketPlace.addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
   
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
    
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer alowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.revertedWith('StartFiMarketPlaceSpecialOffer: Already exisit')
  })


  it('Special offer Should create auction only using the deal terms', async () => {
   
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      insuranceAmount,
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
 
 
  it('user can buy  an item on marketplace  using the offer terms', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, forSalePrice)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -forSalePrice)
    const platformShare =Math.round(calcFees(forSalePrice,offers[0]. _fee,offers[0]. _feeBase))
    const platformWrongShare =Math.round(calcFees(forSalePrice,_feeFraction,_feeBase))
    console.log(platformShare,platformWrongShare,'shares');
    
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(forSalePrice-platformShare)
    expect(await token.balanceOf(admin.address)).to.not.eq(platformWrongShare)
    expect(await token.balanceOf(issuer.address)).to.not.eq(forSalePrice-platformWrongShare)
// check balance 
// check balance 
  })
  
  })
describe('StartFi marketPlace : special Offers with Auction bid only', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
 
    _listqualifyPercentage:20,
 
    _listqualifyPercentageBase:10,
    _feeBase:10
}]
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

  it('non admin can not add special offer ', async () => {
    await expect(marketPlace.addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
   
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
    
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer alowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.revertedWith('StartFiMarketPlaceSpecialOffer: Already exisit')
  })


  it('Special offer Should create auction only using the deal terms', async () => {
   
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      insuranceAmount,
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
 
  it('deposit stakes', async () => {
    const stakeAmount = insuranceAmount;
    
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
    await expect(marketPlace.bid(listingId1, minimumBid+1000)).to.emit(marketPlace, 'BidOnAuction')

  })
  it('Should  fulfill auction when ended after allowing token to pay', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1);
 
    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
    await provider.send('evm_mine',[]);
    const winnerBid= await marketPlace.winnerBid(listingId1)
  
    await expect(token.approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
    await expect(marketPlace.fulfillBid(listingId1)).to.emit(marketPlace,  'FulfillBid')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( wallet.address)
    const platformShare =Math.round(calcFees(winnerBid.bidPrice,offers[0]. _fee,offers[0]. _feeBase))
    const platformWrongShare =Math.round(calcFees(winnerBid.bidPrice,_feeFraction,_feeBase))
    console.log(platformShare,platformWrongShare,'shares');
    
    expect(await token.balanceOf(admin.address)).to.eq(BigNumber.from(platformShare))
    expect(await token.balanceOf(issuer.address)).to.eq(BigNumber.from(winnerBid.bidPrice-platformShare))
    expect(await token.balanceOf(admin.address)).to.not.eq(BigNumber.from(platformWrongShare))
    expect(await token.balanceOf(issuer.address)).to.not.eq(BigNumber.from(winnerBid.bidPrice-platformWrongShare))
 })
  
  })
describe('StartFi marketPlace : special Offers with Auction then delist', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
 
    _listqualifyPercentage:20,
 
    _listqualifyPercentageBase:10,
    _feeBase:10
}]
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

  it('non admin can not add special offer ', async () => {
    await expect(marketPlace.addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
   
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
    
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer alowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
 
      offers[0].  _listqualifyPercentage,
 
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.revertedWith('StartFiMarketPlaceSpecialOffer: Already exisit')
  })


  it('Special offer Should create auction only using the deal terms', async () => {
   
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
  expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).createAuction(  NFT.address,
      marketplaceTokenId1,

      minimumBid,
      insuranceAmount,
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

  it('Should  delist auction when ended with special terms', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1);
 
    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
    await provider.send('evm_mine',[]);
   
     await expect(marketPlace.connect(issuer).deList(listingId1)).to.emit(marketPlace,  'DeListOffMarketplace')
     expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( issuer.address)

    })
  
  })