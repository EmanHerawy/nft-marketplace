import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
const { MaxUint256 } = constants
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)

let NFT: Contract
let payment: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
/**@dev change the visibility to public in order for passing all the tests  */
describe('StartFi Marketplace Lisitng', () => {
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
  })
  // it('Should list on the marketplace', async () => {
  //   const listingOnMarketplace = await marketPlace._listOnMarketPlace(NFT.address, tokenId, 10)
  //   expect(listingOnMarketplace.from).to.eq(wallet.address)
  // })
  // it('Should create auction for item', async () => {
  //   const createAuction = await marketPlace._creatAuction(NFT.address, tokenId, 10, 11, true, 11, 1000000000)
  //   expect(createAuction.from).to.eq(wallet.address)
  // }) // _changeDelistAfter
  // it('should delist item from marketplace', async () => {
  //   const result = await marketPlace._tokenListings(0)
  //   console.log('listiiiiingggg', result)
  //   /*     const createAuction = await marketPlace._delist()
  //   expect(createAuction.from).to.eq(wallet.address) */
  // })
  /*   it('should delist item from marketplace', async () => {
    const createAuction = await marketPlace._delist(NFT.address, tokenId, 10, 11, true, 11, 1000000000)
    expect(createAuction.from).to.eq(wallet.address)
  }) */
})
