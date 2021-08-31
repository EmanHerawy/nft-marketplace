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

  it('ListOnMarketplace: Not enough reserves', async () => {
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Not enough reserves'
    )
  })
  it('deposit stakes', async () => {
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
  })
  it('list on marketplace should not be allowed if marketplace is not approved', async () => {
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })
  it('Should list on marketplace', async () => {
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })
  it('user can not buy with price lower than the list price', async () => {
    await expect(marketPlace.connect(user1).buyNow(listingId1, wrongPrice)).to.revertedWith(
   'Invalid price'
    )
  })
  it('user can not buy without allowing marketplace to transfer tokens', async () => {
    await expect(marketPlace.connect(user1).buyNow(listingId1, price1)).to.revertedWith(
      'Marketplace is not allowed to withdraw the required amount of tokens'
    )
  })
  it('user can buy  an item on marketplace', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1, price1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq( user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT -price1)
    const platformShare =Math.round(calcFees(price1,_feeFraction,_feeBase))
    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(price1-platformShare)
// check balance 
  })
  it('Can not delist already bought item ', async () => {
   await expect(marketPlace.connect(issuer).deList(listingId1)).to.revertedWith('Already bought token')
        
  })
// delist and lost reserves
it('Should delist item and lose stakes', async () => {
  const stakeAmount =  calcFees(price1,listqualifyPercentage,listqualifyPercentageBase);
  console.log(stakeAmount,'stakeAmount');
  
  // await expect(token.approve(stakes.address, stakeAmount))
  //   .to.emit(token, 'Approval')
  //   .withArgs(wallet.address, stakes.address, stakeAmount)
  // expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

  // await stakes.deposit(issuer.address, stakeAmount)
  const reserves = await stakes.getReserves(issuer.address)
  expect(reserves.toNumber()).to.eq(stakeAmount)

  const stakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
  expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
   await expect(NFT.transferFrom(wallet.address,issuer.address, marketplaceTokenId2))
  .to.emit(NFT, 'Transfer')
  .withArgs(wallet.address, issuer.address, marketplaceTokenId2)
  await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId2))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId2)
  expect(await NFT.getApproved(marketplaceTokenId2)).to.eq(marketPlace.address)
  await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId2, price1)).to.emit(
    marketPlace,
    'ListOnMarketplace'
  )
  const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
  const events = await marketPlace.queryFilter(eventFilter)
   listingId2=(events[events.length - 1] as any).args[0]
  await expect(marketPlace.connect(issuer).deList(listingId2))
    .to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId2)).to.eq( issuer.address)

    const newStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    expect(newStakeAllowance.toNumber()).to.eq(0)
    const eventFilter2 = await marketPlace.filters.DeListOffMarketplace(null, null )
    const events2 = await marketPlace.queryFilter(eventFilter2)
    const fineAmount=(events2[events2.length - 1] as any).args[4].toNumber()
    const remaining=(events2[events2.length - 1] as any).args[5].toNumber()
     console.log(fineAmount,remaining,'events2 marketplaceTokenId1');
    
})
it('Can not delist already de listed item ', async () => {
  await expect(marketPlace.connect(issuer).deList(listingId2)).to.revertedWith('Already bought or canceled token')
       
 })
it('non owner can not delist ', async () => {
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
  await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId2))
    .to.emit(NFT, 'Approval')
    .withArgs(issuer.address, marketPlace.address, marketplaceTokenId2)
  expect(await NFT.getApproved(marketplaceTokenId2)).to.eq(marketPlace.address)
  await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId2, price1)).to.emit(
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
console.log(stakeAllowance,'listingDetails');

  await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()]); 
  await provider.send('evm_mine',[]);
  await expect(marketPlace.connect(issuer).deList(listingId2))
    .to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId2)).to.eq( issuer.address)

    const newStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)
    console.log(newStakeAllowance,'newStakeAllowance');
    
    expect(newStakeAllowance.toNumber()).to.eq(stakeAllowance)
 
    
})


  })


describe('StartFi marketPlace : WithPremit', () => {
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
   // the 3 user need to get balance

   await token.transfer(user1.address,TEST_AMOUNT );
   await token.transfer(user2.address,TEST_AMOUNT );
   await token.transfer(user3.address,TEST_AMOUNT );
  })

  it('deposit stakes', async () => {
    const stakeAmount =  calcFees(price1,listqualifyPercentage,listqualifyPercentageBase);
    console.log(stakeAmount,'stakeAmount');
    
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
  // it('Should list on marketplace:permit', async () => {
  //    await expect(
  //    await marketPlace._supportPremit(NFT.address)
  //   ).to.eql(true)
  // })
  it('Should list on marketplace:permit', async () => {
    const nonce = await NFT.nonces(wallet.address)
    const chainId = await NFT.getChainId()
    const deadline = MaxUint256
    const digest = await getApprovalNftDigest(
      NFT,
      { owner: wallet.address, spender: marketPlace.address, tokenId: marketplaceTokenId2 },
      nonce,
      deadline,
      chainId
    )
    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))
    await expect(
      await marketPlace.listOnMarketplaceWithPremit(
        NFT.address,
        marketplaceTokenId2,
        price1,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'ListOnMarketplace')
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1=(events[events.length - 1] as any).args[0]
  })

  it('user can buynow:permit', async () => {
    const nonce = await token.nonces(user1.address)  
    const deadline = MaxUint256
    const digest = await getApprovalDigest(
      token,
      { owner: user1.address, spender: marketPlace.address, value: BigNumber.from(price1 )},
      nonce,
      deadline,
      BigNumber.from(0),
    )

    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1.privateKey.slice(2), 'hex'))
     await expect(
      await marketPlace.connect(user1).buyNowWithPremit(
       listingId1,
       price1,
        deadline,
        v,
        hexlify(r),
        hexlify(s)
      )
    ).to.emit(marketPlace, 'BuyNow')
  })

})