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
const bidPenaltyPercentage = 1; // 1 %
const   delistFeesPercentage = 1;
const   listqualifyPercentage = 10;
const   bidPenaltyPercentageBase = 100;
const   delistFeesPercentageBase = 100;
const   listqualifyPercentageBase = 10;
const royaltyShare=25
const royaltyBase=10
const mintedNFT=[0,1,2,3,4,5,6,7,8,9];
// let marketplaceTokenId1 = mintedNFT[0]
let marketplaceTokenId1:any;
let marketplaceTokenId2 =  mintedNFT[1]
let auctionTokenId =  mintedNFT[2]
let listingId1:any;
let listingId2:any;
let price1=1000;
let price2=10000;
let price3=50050;
let wrongPrice=10;
let minimumBid=10;
let lastbidding=minimumBid;
let isForSale=false;
const calcFees=(price:number,share:number,base:number):number=>{

  // round decimal to the nearst value
  const _base = base * 100;
 return price*(share/_base);

}
describe('StartFi marketPlace', () => {
  const provider = new MockProvider()
  const [wallet, user1,user2,user3,issuer,admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers=[{
    wallet:issuer.address,
    _delistAfter:60*60*24*15,//15 days
    _fee:30, // 2.5% fees
    _bidPenaltyPercentage:20, // 1 %
    _delistFeesPercentage:20,
    _listqualifyPercentage:20,
    _bidPenaltyPercentageBase:10,
    _delistFeesPercentageBase:10,
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
      offers[0]. _bidPenaltyPercentage, // 1 %
      offers[0]._delistFeesPercentage,
      offers[0].  _listqualifyPercentage,
      offers[0]._bidPenaltyPercentageBase,
      offers[0]. _delistFeesPercentageBase,
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.be.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('admin can  add special offer ', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
      offers[0]. _bidPenaltyPercentage, // 1 %
      offers[0]._delistFeesPercentage,
      offers[0].  _listqualifyPercentage,
      offers[0]._bidPenaltyPercentageBase,
      offers[0]. _delistFeesPercentageBase,
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)).to.emit(marketPlace,'NewOffer')
      .withArgs(admin.address,offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
      offers[0]. _bidPenaltyPercentage, // 1 %
      offers[0]._delistFeesPercentage,
      offers[0].  _listqualifyPercentage,
      offers[0]._bidPenaltyPercentageBase,
      offers[0]. _delistFeesPercentageBase,
      offers[0]._listqualifyPercentageBase,
      offers[0].  _feeBase)
  })
  it('No duplicated special offer alowed', async () => {
    await expect(marketPlace.connect(admin).addOffer(offers[0].wallet,  
      offers[0]. _delistAfter,
      offers[0]. _fee, // 2.5% fees
      offers[0]. _bidPenaltyPercentage, // 1 %
      offers[0]._delistFeesPercentage,
      offers[0].  _listqualifyPercentage,
      offers[0]._bidPenaltyPercentageBase,
      offers[0]. _delistFeesPercentageBase,
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
    await expect(marketPlace.connect(user1).buyNow(listingId1, price1)).to.emit(marketPlace, 'BuyNow')
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
