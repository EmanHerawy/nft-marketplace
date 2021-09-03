import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'


import { tokenFixture } from './shared/fixtures'

chai.use(solidity)
let token: Contract
let NFT: Contract
let payment: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
/**@dev change the visibility to public in order for passing all the tests  */
describe('StartFi Marketplace Finance', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])

  let token: Contract
  beforeEach(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
  })

  // it('Should pay fin', async () => {
  //   const deduct = await marketPlace._deduct('0xe092b1fa25DF5786D151246E492Eed3d15EA4dAA', wallet.address, 10)
  //   expect(deduct.from).to.eq(wallet.address)
  // })
  // it('add reputation point', async () => {
  //   const points = await marketPlace._addreputationPoints(wallet.address, wallet.address, 10)
  //   expect(points.from).to.eq(wallet.address)
  // })
  /* it('safe transfer/ from', async () => {
    const transferer = await marketPlace._safeTokenTransfer(wallet.address, 1)
    const transfererFrom = await marketPlace._safeTokenTransferFrom(wallet.address, wallet.address, 1)
    expect(transfererFrom.from).to.eq(wallet.address)
  }) */
  // it('set reserve', async () => {
  //   const reserve = await marketPlace._setUserReserves(wallet.address, 1)
  //   expect(reserve.from).to.eq(wallet.address)
  // })
  // it('update reserve', async () => {
  //   const addReserve = await marketPlace._updateUserReserves(wallet.address, 1, true)
  //   const subReserve = await marketPlace._updateUserReserves(wallet.address, 1, true)
  //   expect(addReserve.from).to.eq(wallet.address)
  //   expect(subReserve.from).to.eq(wallet.address)
  // })

})
