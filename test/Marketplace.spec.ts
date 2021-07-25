import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
const { MaxUint256 } = constants;
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract,createFixtureLoader } from 'ethereum-waffle'
 
import { expandTo18Decimals, getApprovalDigest } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)
const name = "StartFiToken";
const symbol = "STFI";
const TOTAL_SUPPLY = expandTo18Decimals(100000000)
const TEST_AMOUNT = expandTo18Decimals(10)
let token: Contract
let NFT: Contract
let payment: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
describe('StartFiToken', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader( [wallet])

  let token: Contract
  beforeEach(async () => {
    const fixture = await loadFixture(tokenFixture)
    token=fixture.token;
    NFT=fixture.NFT;
    payment=fixture.payment;
    marketPlace=fixture.marketPlace;
    reputation=fixture.reputation;
    stakes=fixture.stakes;
  })

  it("list on marketplace should not be allowed if marketplace is not approved", async () => {
    await expect(
      marketPlace.listOnMarketplace(NFT.address, 0, 10)
    ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
  });
})
