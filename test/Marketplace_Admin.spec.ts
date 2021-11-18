import chai, { expect } from 'chai'
import { Contract } from 'ethers'
 import { waffle } from 'hardhat'
const { solidity,  deployContract, createFixtureLoader, provider } =waffle


import { tokenFixture } from './shared/fixtures'

/**
 * scenarios
 *  Marketplace admin has three privileges change marketplace contracts/fees, pause/unpause and update admin wallet
 * 1- Admin can change:
 * -- Used contracts: reputation and utility contracts
 * -- Fulfill bid duration

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

const newTokenAddress = '0x791E48D5eC148191Baa680fE2Dd337D3D5d4A147'
const newReputationAddress = '0x2E81345F9082619d900c0204D0913E904648c6E4'
const twoDays = 2 * 24 * 60 * 60

describe('MarketPlace admin pause contract and start updating contract', () => {
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
    await expect(marketPlace.pause()).to.emit(marketPlace, 'Paused')
  })

  it('Admin should unpause contract', async () => {
    await expect(marketPlace.unpause()).to.emit(marketPlace, 'Unpaused')
  })

  it('Should revert only admin pause contract', async () => {
    await expect(marketPlace.connect(user1).pause()).to.revertedWith('caller is not the owner')
  })
  it('Should revert only admin unpause contract', async () => {
    await expect(marketPlace.connect(user1).unpause()).to.revertedWith(
      'caller is not the owner'
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
      'caller is not the owner'
    )
  })

  it('Admin should change reputation contract:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeReputationContract(newReputationAddress)).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change utility contract ', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeUtilityToken(newTokenAddress))
      .to.emit(marketPlace, 'ChangeUtilityToken')
      .withArgs(newTokenAddress)
  })

  it('Admin should change utility contract:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeUtilityToken(newTokenAddress)).to.revertedWith(
      'caller is not the owner'
    )
  })

  it('Admin should change utility contract:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeUtilityToken(newTokenAddress)).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change fulfil bid duration', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeFulfillDuration(twoDays))
      .to.emit(marketPlace, 'ChangeFulfillDuration')
      .withArgs(twoDays)
  })

  it('Admin should change fulfil bid duration:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeFulfillDuration(twoDays)).to.revertedWith(
      'caller is not the owner'
    )
  })

  it('Admin should change fulfil bid duration:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeFulfillDuration(twoDays)).to.revertedWith('Pausable: not paused')
  })

  it('Fulfil bid duration should not  be less than 1 day', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeFulfillDuration(twoDays / 3)).to.reverted;//With('Invalid duration')
  })

 



 




 

  it('Admin should change fees', async () => {
    
    await expect(marketPlace.changeFees(30,10)).to.emit(marketPlace, 'ChangeFees').withArgs(30,10)
  })

  it('Admin should change fees:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeFees(30,10)).to.revertedWith(
      'caller is not the owner'
    )
  })

  it('Admin should change fees:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeFees(30,10)).to.revertedWith('Pausable: not paused')
  })

  it('Admin should change name', async () => {
    await marketPlace.pause()
    await expect(marketPlace.changeMarketPlaceName('new STFI marketplace'))
      .to.emit(marketPlace, 'ChangeMarketPlaceName')
      .withArgs('new STFI marketplace')
  })
  it('Should set marketCap when paused', async () => {
    const transactionRecipe = await marketPlace.setUsdCap(5)
    expect(transactionRecipe.from).equal(wallet.address)
  })
  it('Admin should change name:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).changeMarketPlaceName('new STFI marketplace')).to.revertedWith(
      'caller is not the owner'
    )
  })

  it('Admin should change name:revert not paused ', async () => {
    await marketPlace.unpause()
    await expect(marketPlace.changeMarketPlaceName('new STFI marketplace')).to.revertedWith('Pausable: not paused')
  })

  it('Admin should update  wallet addrees:revert not the owner ', async () => {
    await expect(marketPlace.connect(user1).updateAdminWallet(user1.address)).to.revertedWith('UnAuthorized')
  })
  it('Admin should update  wallet addrees:revert no zero address', async () => {
    await expect(marketPlace.updateAdminWallet('0x0000000000000000000000000000000000000000')).to.revertedWith(
      'Zero address is not allowed'
    )
  })
  it('Admin should update  wallet address ', async () => {
    await expect(marketPlace.updateAdminWallet(user1.address))
      .to.emit(marketPlace, 'UpdateAdminWallet')
      .withArgs(user1.address)
  })
    it('Should not set marketCap when unpaused', async () => {
     await expect(marketPlace.setUsdCap(5)).to.revertedWith('Pausable: not paused')
  })



  it('Should set STFI price', async () => {
    const transactionRecipe = await marketPlace.setPrice(23)
    expect(transactionRecipe.from).equal(wallet.address)
  })

})
