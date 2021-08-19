import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
const { MaxUint256 } = constants

import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals, getApprovalDigest } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)

describe('Staking STFI', () => {
  let token: Contract
  let NFT: Contract
   let marketPlace: Contract
  let reputation: Contract
  let stakes: Contract
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])

  beforeEach(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
     marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
    await token.approve(stakes.address, 10000000000000)
  })

  it('Should deposit some STFI to stake', async () => {
    await stakes.deposit(wallet.address, 10)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(10)
  })

  it('Should withdraw some STFI from pool', async () => {
    await stakes.deposit(wallet.address, 20)
    await stakes.withdraw(10) // @EH  transaction revert
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(10)
  })

  it('Should deduct user', async () => {
    await stakes.deduct(wallet.address, marketPlace.address, 20)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(10)
  })
})
