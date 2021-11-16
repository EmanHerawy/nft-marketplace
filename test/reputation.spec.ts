import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
const { MaxUint256 } = constants
 import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
/**@dev change the visibility to public in order for passing all the tests  */
describe('StartFi Reputation', () => {
  
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
         expect(await reputation.mintReputation(wallet.address, 20)).to.emit(reputation,"CurrentReputation")
    expect(await reputation.getUserReputation(wallet.address)).to.eq(20);
         expect(await reputation.burnReputation(wallet.address, 10)).to.emit(reputation,"CurrentReputation")
    expect(await reputation.getUserReputation(wallet.address)).to.eq(10);


  })
  // it('Should burn reputation', async () => {

  //        expect(await reputation.burnReputation(wallet.address, 10)).to.emit(reputation,"CurrentReputation")
  //   expect(await reputation.getUserReputation(wallet.address)).to.eq(10);    })
  // // it('should set and get reputation', async () => {
  //   await reputation._setReputation(wallet.address, 10)
  //   const userReputation = await reputation.getUserReputation(wallet.address)
  //   expect(userReputation).to.eq(10) //
  // })
})
