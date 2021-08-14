import chai, { expect } from 'chai'
import { Contract } from 'ethers'
 // BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader,deployContract } from 'ethereum-waffle'
import { tokenFixture } from './shared/fixtures'
import StartFiTokenDistribution from '../artifacts/contracts/StartFiTokenDistributionV2.sol/StartFiTokenDistributionV2.json'

chai.use(solidity)
let startfiToken: Contract
let tokenDistrbution: Contract
let TEST_AMOUNT=5000000;
describe('StartFi Token Distribution V 2', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader( [wallet])

   before(async () => {
    const fixture = await loadFixture(tokenFixture)
    startfiToken=fixture.token;
    tokenDistrbution = await deployContract(wallet, StartFiTokenDistribution, [startfiToken.address,Date.now(),wallet.address])
    // fuel the contract 
    await startfiToken.transfer(tokenDistrbution.address,TEST_AMOUNT)

  })
  beforeEach(async () => {
  //  token = await deployContract(wallet, ERC20, [name,symbol, wallet.address])
  })
// owner can pause 
// owner can unpause 
// owner can withdraw when there's a risk
// beneficiary can withdraw   

it('erc20, paused, owner, tokenOwners', async () => {
  const erc20 = await tokenDistrbution.erc20()    
  expect(erc20).to.eq(startfiToken.address)
  expect(await tokenDistrbution.paused()).to.eq(false)
  expect(await tokenDistrbution.owner()).to.eq(wallet.address)
  expect(await tokenDistrbution.tokenOwners(0)).to.eq(wallet.address)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(wallet.address)).to.eq(4)

  
  const DistributionStep = await tokenDistrbution.getBeneficiaryPoolInfo(wallet.address,0)
  console.log(DistributionStep,'DistributionStep');


  expect(await startfiToken.balanceOf(tokenDistrbution.address)).to.eq(TEST_AMOUNT)
 /** const TGEDate = await tokenDistrbution.TGEDate();
  const info = await tokenDistrbution.getData();
  console.log(TGEDate,'TGEDate');
  console.log(info,'info');
  expect(info[2]).to.eq(Date.now()) */
})
it('Paused', async () => {
  await expect(tokenDistrbution.pause())
    .to.emit(tokenDistrbution, 'Paused')
    .withArgs(wallet.address)
  expect(await tokenDistrbution.paused()).to.eq(true)
})
it('owner can  call safeGuardAllTokens to transfer all tokens that contract has when bug found', async () => {
  // await expect(tokenDistrbution.pause())
  // .to.emit(tokenDistrbution, 'Paused')
  // .withArgs(wallet.address)
expect(await tokenDistrbution.paused()).to.eq(true)
  await expect(tokenDistrbution.safeGuardAllTokens( other.address))
    .to.emit(startfiToken, 'Transfer')
    .withArgs(tokenDistrbution.address, other.address, TEST_AMOUNT)
    expect(await startfiToken.balanceOf(other.address)).to.eq(TEST_AMOUNT)
})
it('Unpaused', async () => {
  await expect(tokenDistrbution.unpause())
    .to.emit(tokenDistrbution, 'Unpaused')
    .withArgs(wallet.address)
  expect(await tokenDistrbution.paused()).to.eq(false)
})
it('anyone can  call triggerTokenSend to transfer distributed tokens when not paused', async () => {
  const TGEDate = await tokenDistrbution.TGEDate();
  // const time = Date.now() + 86400
  await provider.send('evm_increaseTime', [TGEDate.toNumber()]); 
  await provider.send('evm_mine',[]);
expect(await tokenDistrbution.paused()).to.eq(false)
const balance= await startfiToken.balanceOf(tokenDistrbution.address)
console.log(balance.toNumber(),'balance.toNumber()');
// for some resone , balance is reset to 0 and we have to refund it
if(balance.toNumber()==0){
  await startfiToken.transfer(tokenDistrbution.address,TEST_AMOUNT)

}
  await expect(tokenDistrbution.triggerTokenSend())
     .to.emit(startfiToken, 'Transfer')

    
})


it('non Owner can not pause', async () => {
  await expect(tokenDistrbution.connect(other).pause()).to.be.reverted;
})
it('non Owner can not unpause', async () => {
  await expect(tokenDistrbution.connect(other).unpause()).to.be.reverted;
   
})
it('owner can not call safeGuardAllTokens to transfer all tokens when contract is not paused', async () => {
  await expect(tokenDistrbution.safeGuardAllTokens( other.address)).to.be.reverted;
})

it('non Owner can call safeGuardAllTokens', async () => {
  await expect(tokenDistrbution.connect(other).safeGuardAllTokens( other.address)).to.be.reverted;
})
it('Can not  call triggerTokenSend when paused', async () => {
  await expect(tokenDistrbution.pause())
    .to.emit(tokenDistrbution, 'Paused')
    .withArgs(wallet.address)
  expect(await tokenDistrbution.paused()).to.eq(true)
  await expect(tokenDistrbution.triggerTokenSend())
     .to.be.reverted
   
})

})
