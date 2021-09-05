import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
const { MaxUint256 } = constants
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals, getApprovalDigest } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
/**@dev change the visibility to public in order for passing all the tests  */
describe('StartFi Reputation', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const tokenId = 0
  let token: Contract
  beforeEach(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
    await reputation.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', wallet.address)
  })
  it('Should mint reputation', async () => {
    const mintReputation = await reputation.mintReputation(wallet.address, 10)
    expect(mintReputation.from).to.eq(wallet.address)
  })
  it('Should burn reputation', async () => {
    const burnReputation = await reputation.burnReputation(wallet.address, 10)
    expect(burnReputation.from).to.eq(wallet.address) //_setReputation
  })
  // it('should set and get reputation', async () => {
  //   await reputation._setReputation(wallet.address, 10)
  //   const userReputation = await reputation.getUserReputation(wallet.address)
  //   expect(userReputation).to.eq(10) //
  // })
})
