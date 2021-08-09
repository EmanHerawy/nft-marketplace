import chai, { expect } from 'chai'
import { Contract } from 'ethers'
 // BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'
 

import { tokenFixture } from './shared/fixtures'

chai.use(solidity)
let startfiToken: Contract
let NFT: Contract
let startFiPaymentNFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
describe('StartFi marketPlace', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader( [wallet])

   before(async () => {
    const fixture = await loadFixture(tokenFixture)
    startfiToken=fixture.token;
    NFT=fixture.NFT;
    startFiPaymentNFT=fixture.payment;
    marketPlace=fixture.marketPlace;
    reputation=fixture.reputation;
    stakes=fixture.stakes;
  })
  it("Should grant admin role", async () => {
    const grantMinterRole = await NFT.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiPaymentNFT.address
    );
    expect(grantMinterRole.from).to.be.equal(wallet.address);
  });
  it("Should mint without royalty", async () => {
    await NFT.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiPaymentNFT.address
    );
    await startfiToken.approve(startFiPaymentNFT.address, "10000000000000");
    const mint = await startFiPaymentNFT.MintNFTWithoutRoyalty(
      wallet.address,
      "001"
    );
    expect(mint.from).to.be.equal(wallet.address);
  });
  it("Should mint with royalty", async () => {
    await NFT.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiPaymentNFT.address
    );
    await startfiToken.approve(startFiPaymentNFT.address, "10000000000000");
    const mint = await startFiPaymentNFT.MintNFTWithRoyalty(
      wallet.address,
      "001",
      "1",
      "10"
    );
    expect(mint.from).to.be.equal(wallet.address);
  });
  it("Should change fees", async () => {
    await startFiPaymentNFT.changeFees("4");
    const info = await startFiPaymentNFT.info();
    expect(info[2].toNumber()).to.be.equal(4);
  });
 it("Should change NFT contract", async () => {
    await startFiPaymentNFT.changeNftContract(wallet.address);
    const info = await startFiPaymentNFT.info();
    expect(info[0]).to.be.equal(wallet.address);
  });
 it("Should change Payment contract", async () => {
    await startFiPaymentNFT.changePaymentContract(wallet.address);
    const info = await startFiPaymentNFT.info();
    expect(info[1]).to.be.equal(wallet.address);
  });
})
