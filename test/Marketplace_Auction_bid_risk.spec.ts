import chai, { expect } from 'chai'
import { Contract  } from 'ethers'
 
  import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle
 import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
 /**
 * scenarios
 for instance, there are four auctions ongoing and each of the auctions is
for bidding a different NFT item. Based on the existing implementation a bidder can deposit only
ONE deposit but can participate in all these four auctions. This might not be your desired
behavior, right ?



** todo : create 4 auction ( auction 1 requires 100, two: 110,three 120 and four :100, sume is 430 required stakes) , stake 400, 
 *  1- check that the allowedstakes is decreased with each first bid only 
 * 2- user can't bid on auction 4
 */
chai.use(solidity)
const TEST_AMOUNT = 100000000 //expandTo18Decimals(10)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

const _feeFraction = 25 // 2.5% fees
const _feeBase = 10

const royaltyShare = 25
const royaltyBase = 10
const mintedNFT = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
let marketplaceTokenId1: any
let listingId0: any
let listingId1: any
let listingId2: any
let listingId3: any
const auction1Insurance = 100
const auction2Insurance = 110
const auction3Insurance = 120
const auction4Insurance = 100
const totalDeposit = 400
let zeroPrice = 0
let price1 = 1000
let insuranceAmount = 10
let minimumBid = 10
let duration = 60 * 60 * 15 // 15 hours
let isForSale = false
let forSalePrice = 10000
const calcFees = (price: number, share: number, base: number): number => {
  // round decimal to the nearst value
  const _base = base * 100
  return price * (share / _base)
}
describe('StartFi marketPlace:Actions create  bid and for sale as well , bid and buyNow, now bid after purchase', () => {
  
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
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
    ])

 

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)
  })

  it('approve the 4 nfts ', async () => {
    for (let index = 0; index < 4; index++) {
      await await expect(NFT.approve(marketPlace.address, index))
        .to.emit(NFT, 'Approval')
        .withArgs(wallet.address, marketPlace.address, index)
      expect(await NFT.getApproved(index)).to.eq(marketPlace.address)
    }
  })

  it('Should create auction 1 that accepts bid', async () => {
    await expect(
      marketPlace.createAuction(
        NFT.address,
        0,

        minimumBid,
        auction1Insurance,
        isForSale,
        0,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId0 = (events[events.length - 1] as any).args[0]
  })

  it('Should create auction 2 that accepts bid', async () => {
    await expect(
      marketPlace.createAuction(
        NFT.address,
        1,

        minimumBid,
        auction2Insurance,
        isForSale,
        0,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]
  })
  it('Should create auction 3 that accepts bid', async () => {
    await expect(
      marketPlace.createAuction(
        NFT.address,
        2,

        minimumBid,
        auction3Insurance,
        isForSale,
        0,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId2 = (events[events.length - 1] as any).args[0]
  })
  it('Should create auction 4 that accepts bid', async () => {
    await expect(
      marketPlace.createAuction(
        NFT.address,
        3,

        minimumBid,
        auction4Insurance,
        isForSale,
        0,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId3 = (events[events.length - 1] as any).args[0]
  })

  // bid

  it('deposit 400 stakes', async () => {

    await expect(token.connect(user1).approve(stakes.address, totalDeposit))
      .to.emit(token, 'Approval')
      .withArgs(user1.address, stakes.address, totalDeposit)
    expect(await token.allowance(user1.address, stakes.address)).to.eq(totalDeposit)
 
    await stakes.connect(user1).deposit(user1.address, totalDeposit)
    const reserves = await stakes.getReserves(user1.address)
    expect(reserves.toNumber()).to.eq(totalDeposit)

    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    expect(stakeAllowance.toNumber()).to.eq(totalDeposit)
  })

  it('Should  bid on item with price equal or more than the mini bid price, allowed stakes should be 300', async () => {
    await expect(marketPlace.connect(user1).bid(listingId0, minimumBid + 1)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - auction1Insurance)
  })
  it('Should  bid for the second time on item without decreasing the staks', async () => {
    await expect(marketPlace.connect(user1).bid(listingId0, minimumBid + 120)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - auction1Insurance)
  })
  it('Should  bid on item with price equal or more than the mini bid price, allowed stakes should be 190', async () => {
    await expect(marketPlace.connect(user1).bid(listingId1, minimumBid + 1)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - (auction1Insurance + auction2Insurance))
  })
  it('Should  bid for the second time on item without decreasing the staks', async () => {
    await expect(marketPlace.connect(user1).bid(listingId1, minimumBid + 100)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - (auction1Insurance + auction2Insurance))
  })
  it('Should  bid on item with price equal or more than the mini bid price, allowed stakes should be 70', async () => {
    await expect(marketPlace.connect(user1).bid(listingId2, minimumBid + 1)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - (auction1Insurance + auction2Insurance + auction3Insurance))
  })
  it('Should  bid for the second time on item without decreasing the staks', async () => {
    await expect(marketPlace.connect(user1).bid(listingId2, minimumBid + 100)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - (auction1Insurance + auction2Insurance+ auction3Insurance))
  })
  it('Should not bid in the 4th auction, not enough reserves', async () => {
       await expect(marketPlace.bid(listingId3,minimumBid +1)).to.revertedWith('Not enough reserves')
  })


})
