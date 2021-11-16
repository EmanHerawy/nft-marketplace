import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
 import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)

let NFT: Contract
let payment: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
/**@dev change the visibility to public in order for passing all the tests  */
describe('StartFi Marketplace Lisitng', () => {
  
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
  // })
  /*   it('should delist item from marketplace', async () => {
    const createAuction = await marketPlace._delist(NFT.address, tokenId, 10, 11, true, 11, 1000000000)
    expect(createAuction.from).to.eq(wallet.address)
  }) */
})
