import chai, { expect } from 'chai'
import { Contract } from 'ethers'
 // BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
 import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle
import { tokenFixture } from './shared/fixtures'
import StartFiTokenDistribution from '../artifacts/contracts/StartFiTokenDistribution.sol/StartFiTokenDistribution.json'
import { expandTo18Decimals } from './shared/utilities'

chai.use(solidity)
let startfiToken: Contract
let tokenDistrbution: Contract
let TEST_AMOUNT= expandTo18Decimals(99000000);
console.log(TEST_AMOUNT,'TEST_AMOUNT');

const  tokenOwners =["0xAA4e7Ab6dccc1b673036B6FF78fe8af3402801c6",
  "0x438A078871C6e24663381CDcC7E85C42a0BD5a92",
  "0x0140d69F99531C10Da3094b5E5Ca758FA0F31579",
  "0x5deBAB9052E18f9E54eCECdD93Ee713d0ED64CBd",
  "0x907CB9388f6C78D1179b82A2F6Cc2aB4Ef1534E7",
  "0xcDC0b435861d452a0165dD939a8a31932055B08B",
  "0x492eC1E39724Dfc7F4d2b42083BCeb339eBaf18f",
  "0x801b877ECD8ef397F8560CbFAABd1C910BC8230E"]
  const seedAccount =tokenOwners[0];
  const privateSaleAccount =tokenOwners[1];
  const treasuryFundAccount =tokenOwners[2];
  const liquidityAccount =tokenOwners[3];
  const communityPartnerAccount =tokenOwners[4];
  const rewardAccount =tokenOwners[5];
  const teamAccount =tokenOwners[6];
  const advisorAccount =tokenOwners[7];
describe('StartFi Token Distribution V 2', () => {
  
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader( [wallet])

   before(async () => {
    const fixture = await loadFixture(tokenFixture)
    startfiToken=fixture.token;
    tokenDistrbution = await deployContract(wallet, StartFiTokenDistribution, [startfiToken.address,1629072000,wallet.address])
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
  expect(await tokenDistrbution.tokenOwners(0)).to.eq(seedAccount)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(seedAccount)).to.eq(11)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(privateSaleAccount)).to.eq(11)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(treasuryFundAccount)).to.eq(4)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(liquidityAccount)).to.eq(4)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(communityPartnerAccount)).to.eq(20)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(rewardAccount)).to.eq(25)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(teamAccount)).to.eq(5)
  expect(await tokenDistrbution.getBeneficiaryPoolLength(advisorAccount)).to.eq(7)
 
  
  // const DistributionStep = await tokenDistrbution.getBeneficiaryPoolInfo(seedAccount,0)
  // console.log(DistributionStep,'DistributionStep');


  expect(await startfiToken.balanceOf(tokenDistrbution.address)).to.eq(TEST_AMOUNT)
 /** const TGEDate = await tokenDistrbution.TGEDate();
  const info = await tokenDistrbution.getData();
  console.log(TGEDate,'TGEDate');
  console.log(info,'info');
  expect(info[2]).to.eq(Date.now()) */
})
it('anyone can  call triggerTokenSend to transfer distributed tokens when not paused', async () => {
  const TGEDate = await tokenDistrbution.TGEDate();
   // const time = Date.now() + 86400
  await provider.send('evm_increaseTime', [TGEDate.toNumber()]); 
  await provider.send('evm_mine',[]);
expect(await tokenDistrbution.paused()).to.eq(false)
  await expect(tokenDistrbution.triggerTokenSend())
     .to.emit(startfiToken, 'Transfer')
  await expect(tokenDistrbution.triggerTokenSend())
     .to.not.emit(startfiToken, 'Transfer')

    
})
it('Paused', async () => {
  await expect(tokenDistrbution.pause())
    .to.emit(tokenDistrbution, 'Paused')
    .withArgs(wallet.address)
  expect(await tokenDistrbution.paused()).to.eq(true)
})
it('owner can  call safeGuardAllTokens to transfer all tokens that contract has when bug found', async () => {
  const balance= await startfiToken.balanceOf(tokenDistrbution.address)

expect(await tokenDistrbution.paused()).to.eq(true)
  await expect(tokenDistrbution.safeGuardAllTokens( other.address))
    .to.emit(startfiToken, 'Transfer')
    .withArgs(tokenDistrbution.address, other.address, balance)
    expect(await startfiToken.balanceOf(other.address)).to.eq(balance)
})
it('Unpaused', async () => {
  await expect(tokenDistrbution.unpause())
    .to.emit(tokenDistrbution, 'Unpaused')
    .withArgs(wallet.address)
  expect(await tokenDistrbution.paused()).to.eq(false)
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
