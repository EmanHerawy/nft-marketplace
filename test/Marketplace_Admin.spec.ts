import chai, { expect } from 'chai'
import { Contract, constants, utils, BigNumber } from 'ethers'

import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'

/**
 * scenarios
 *  Marketplace admin has three privileges change marketplace contracts/fees, pause/unpause and update admin wallet
 * 1- Admin can change:
 * -- Used contracts: reputation and utility contracts
 * -- Fulfill bid duration
 * -- List qualify amount
 * -- Delist fees percentage
 * -- Time to delist
 * -- Bid penalty percentage
 * -- Marketplace name
 * -- Marketplace fees
 * In order to submit any of the following transaction you need to be the owner and the contract should be paused
 * *************
 * 2- Pause/Unpause contract
 * -- Admin can change status to be paused to make the above changes
 * -- Admin can't change state the current state
 * *************
 * 3- Admin can update his wallet
 * -- Change admin wallet
 * -- Should be the owner
 * -- new wallet address shouldn't be zero
 */

chai.use(solidity)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
let adminMarketplace: Contract

const _feeFraction = 25 // 2.5% fees
const _feeBase = 10
const bidPenaltyPercentage = 1 // 1 %
const delistFeesPercentage = 1
const listqualifyPercentage = 10
const bidPenaltyPercentageBase = 100
const delistFeesPercentageBase = 100
const listqualifyPercentageBase = 10
const royaltyShare = 25
const royaltyBase = 10
const mintedNFT = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
// let marketplaceTokenId1 = mintedNFT[0]
let marketplaceTokenId1: any
let marketplaceTokenId2 = mintedNFT[1]
let auctionTokenId = mintedNFT[2]
let listingId1: any
let listingId2: any
let price1 = 1000
let price2 = 10000
let price3 = 50050
let wrongPrice = 10
let minimumBid = 10
let lastbidding = minimumBid
let isForSale = false
const newTokenAddress = '0x791E48D5eC148191Baa680fE2Dd337D3D5d4A147'
const newReputationAddress = '0x2E81345F9082619d900c0204D0913E904648c6E4'
const calcFees = (price: number, share: number, base: number): number => {
  // round decimal to the nearst value
  const _base = base * 100
  return price * (share / _base)
}
describe('MarketPlace admin pause contract and start updating contract', () => {
  const provider = new MockProvider()
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,
      _delistAfter: 60 * 60 * 24 * 15, //15 days
      _fee: 30, // 2.5% fees
      _bidPenaltyPercentage: 20, // 1 %
      _delistFeesPercentage: 20,
      _listqualifyPercentage: 20,
      _bidPenaltyPercentageBase: 10,
      _delistFeesPercentageBase: 10,
      _listqualifyPercentageBase: 10,
      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    adminMarketplace = fixture.marketPlace
  })

  it('Admin should pause contract', async () => {
    await expect(adminMarketplace.pause()).to.emit(adminMarketplace, 'Pause')
  })

  it('Admin should unpause contract', async () => {
    await expect(adminMarketplace.unpause()).to.emit(adminMarketplace, 'Unpause')
  })

  it('Should revert only admin pause contract', async () => {
    await expect(adminMarketplace.connect(user1).pause()).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })
  it('Should revert only admin unpause contract', async () => {
    await expect(adminMarketplace.connect(user1).unpause()).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it("To pause contract it shouldn't be already paused", async () => {
    await adminMarketplace.pause()
    await expect(adminMarketplace.pause()).to.revertedWith('Pausable: paused')
  })
  it("To unpause contract it shouldn't be already unpaused", async () => {
    await adminMarketplace.unpause()
    await expect(adminMarketplace.unpause()).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change reputation contract ', async () => {
    await adminMarketplace.pause()
    await expect(adminMarketplace.changeReputationContract(newReputationAddress))
      .to.emit(adminMarketplace, 'ChangeReputationContract')
      .withArgs(newReputationAddress)
  })

  it('Admin should change reputation contract:revert not the owner ', async () => {
    await expect(adminMarketplace.connect(user1).changeReputationContract(newReputationAddress)).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it('Admin should change reputation contract:revert not paused ', async () => {
    await adminMarketplace.unpause()
    await expect(adminMarketplace.changeReputationContract(newReputationAddress)).to.revertedWith(
      'Pausable: not paused'
    )
  })
})
