import chai, { expect } from 'chai'
import { Contract } from 'ethers'

import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

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

const newTokenAddress = '0x791E48D5eC148191Baa680fE2Dd337D3D5d4A147'
const newReputationAddress = '0x2E81345F9082619d900c0204D0913E904648c6E4'
const twoDays = 2 * 24 * 60 * 60

describe('MarketPlace admin pause contract and start updating contract', () => {
  const provider = new MockProvider()
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])

  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    marketPlace = fixture.marketPlace
  })

  it('Admin should pause contract', async () => {
    await expect(marketPlace.pause()).to.emit(marketPlace, 'Pause')
  })

  it('Admin should unpause contract', async () => {
    await expect(marketPlace.unpause()).to.emit(marketPlace, 'Unpause')
  })

  it('Should revert only admin pause contract', async () => {
    await expect(marketPlace.connect(user1).pause()).to.revertedWith('StartFiMarketPlaceAdmin: caller is not the owner')
  })
  it('Should revert only admin unpause contract', async () => {
    await expect(marketPlace.connect(user1).unpause()).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it("To pause contract it shouldn't be already paused", async () => {
    await marketPlace.pause()
    await expect(marketPlace.pause()).to.revertedWith('Pausable: paused')
  })
  it("To unpause contract it shouldn't be already unpaused", async () => {
    await marketPlace.unpause()
    await expect(marketPlace.unpause()).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change reputation contract ', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeReputationContract(newReputationAddress))
      .to.emit(marketPlace, 'ChangeReputationContract')
      .withArgs(newReputationAddress)
  })

  it('Admin should change reputation contract:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeReputationContract(newReputationAddress)).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it('Admin should change reputation contract:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeReputationContract(newReputationAddress)).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change utility contract ', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeUtiltiyToken(newTokenAddress))
      .to.emit(marketPlace, 'ChangeUtiltiyToken')
      .withArgs(newTokenAddress)
  })

  it('Admin should change utility contract:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeUtiltiyToken(newTokenAddress)).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it('Admin should change utility contract:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeUtiltiyToken(newTokenAddress)).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change fulfil bid duration', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeFulfillDuration(twoDays))
      .to.emit(marketPlace, 'ChangeFulfillDuration')
      .withArgs(twoDays)
  })

  it('Admin should change fulfil bid duration:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeFulfillDuration(twoDays)).to.revertedWith(
      'StartFiMarketPlaceAdmin: caller is not the owner'
    )
  })

  it('Admin should change fulfil bid duration:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeFulfillDuration(twoDays)).to.revertedWith('Pausable: not paused')
  })

  it('Fulfil bid duration should not  be less than 1 day', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeFulfillDuration(twoDays / 3)).to.revertedWith('Invalid duration')
  })
})
