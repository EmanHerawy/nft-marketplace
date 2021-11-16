import chai, { expect } from 'chai'
import { Contract} from 'ethers'
  import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle
 import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
 /**
 * scenarios
 If we have an auction with a winning bidder , the contract for any reason is paused , then the auction is unpaused but after the fulfilling period is passed , a malicious auction creator can call dispute function  and take the bidder's stakes . 
 */
chai.use(solidity)
const TEST_AMOUNT = 100000000 //expandTo18Decimals(10)
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

let listingId0: any
let listingId1: any

const auction1Insurance = 100
const auction2Insurance = 110

const totalDeposit = 400
let minimumBid = 10
let duration = 60 * 60 * 15 // 15 hours
let isForSale = false
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
      reputation.address,
      admin.address,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)
  })

  it('approve the 2 nfts ', async () => {
    for (let index = 0; index < 2; index++) {
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

  it('Should  bid on item with price equal or more than the mini bid price, allowed stakes should be 190', async () => {
    await expect(marketPlace.connect(user1).bid(listingId1, minimumBid + 1)).to.emit(marketPlace, 'BidOnAuction')
    const stakeAllowance = await marketPlace.getStakeAllowance(user1.address)
    console.log(stakeAllowance.toNumber(), 'stakeAllowance 1')

    expect(stakeAllowance.toNumber()).to.eq(totalDeposit - (auction1Insurance + auction2Insurance))
  })
  it(' pause contract', async () => {
    await expect(marketPlace.connect(admin).pause()).to.emit(marketPlace, 'Paused')
  })

  it('go in time for more than 3 days and unpause contract', async () => {
    const _fulfillDuration = await marketPlace.fulfillDuration()
    console.log(_fulfillDuration, 'fulfillDuration')

    await provider.send('evm_increaseTime', [_fulfillDuration.toNumber() + duration * 5])
    await provider.send('evm_mine', [])
    await expect(marketPlace.connect(admin).unpause()).to.emit(marketPlace, 'Unpaused')
  })
  it('Should not dispute item right after unpause, must wait for fulfill duration', async () => {
    await expect(marketPlace.connect(wallet).disputeAuction(listingId1)).to.revertedWith(
      'Contract has justed unpaused, please give the bidder time to fulfill'
    )
  })

  it('Should fullfil bid item', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, minimumBid + 1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).fulfillBid(listingId1)).to.emit(marketPlace, 'FulfillBid')
  })
  it('Should  dispute item  after unpause and fulfill duration', async () => {
    const _fulfillDuration = await marketPlace.fulfillDuration()
    await provider.send('evm_increaseTime', [_fulfillDuration.toNumber() + duration * 5])
    await provider.send('evm_mine', [])
    await expect(marketPlace.connect(wallet).disputeAuction(listingId0)).to.emit(marketPlace, 'DisputeAuction')
    expect(await NFT.ownerOf(0))
      .to.eq(wallet.address)
  })
})
