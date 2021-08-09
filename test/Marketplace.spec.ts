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
let tokenId=1;
describe('StartFi marketPlace', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader( [wallet])

  let token: Contract
  before(async () => {
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
      marketPlace.listOnMarketplace(NFT.address, tokenId, 10)
    ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
  });
  it('approve', async () => {
    await expect(NFT.approve(marketPlace.address, tokenId))
      .to.emit(NFT, 'Approval')
      .withArgs(wallet.address, marketPlace.address, tokenId)
    expect(await NFT.getApproved(tokenId)).to.eq(marketPlace.address)
  })
  it("ListOnMarketplace: Not enough reserves", async () => {
    await expect(
      marketPlace.listOnMarketplace(NFT.address, tokenId, 1000)
    ).to.be.revertedWith("Not enough reserves");
  });
  it("Should list on marketplace", async () => {
    await expect(
      marketPlace.listOnMarketplace(NFT.address, tokenId, 10)
    ).to.emit(marketPlace, "ListOnMarketplace")//.withArgs(wallet.address, marketPlace.address, tokenId)
    expect(await NFT.ownerOf(tokenId)).to.eq(marketPlace.address)
  });
 
  // it("ListOnMarketplace: revert Marketplace is not allowed to transfer your token", async () => {
  //   await expect(
  //     marketPlace.listOnMarketplace(payment.address, 0, 20)
  //   ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
  // });
  // it("Should create auction on marketplace", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       NFT.address,
  //       0,
  //       10,
  //       11,
  //       true,
  //       11,
  //       1000000000
  //     )
  //   ).to.emit(marketPlace, "CreateAuction");
  // });
  // it("Auction: listing price should not equal zero", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       NFT.address,
  //       0,
  //       0,
  //       11,
  //       true,
  //       2000,
  //       1000000000
  //     )
  //   ).to.be.revertedWith("Zero Value is not allowed");
  // });
  // it("Auction: sell for price should not equal zero", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       NFT.address,
  //       0,
  //       10,
  //       11,
  //       true,
  //       0,
  //       1000000000
  //     )
  //   ).to.be.revertedWith("Zero price is not allowed");
  // });
  // it("Auction: Zero price is not allowed", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       NFT.address,
  //       0,
  //       10,
  //       11,
  //       true,
  //       0,
  //       1000000000
  //     )
  //   ).to.be.revertedWith("Zero price is not allowed");
  // });
  // it("Auction: Marketplace is not allowed to transfer your token", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       payment.address,
  //       0,
  //       10,
  //       11,
  //       true,
  //       11,
  //       1000000000
  //     )
  //   ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
  // });
  // it("Auction should live for more than 12 hours", async () => {
  //   await expect(
  //     marketPlace.createAuction(
  //       NFT.address,
  //       0,
  //       10,
  //       11,
  //       true,
  //       11,
  //       10
  //     )
  //   ).to.be.revertedWith("Auction should be live for more than 12 hours");
  // });

  // it("Should bid item", async () => {
  //   await stakes.deposit(wallet.address, 1000);
  //   await marketPlace.listOnMarketplace(
  //     NFT.address,
  //     1,
  //     10
  //   );
  //   const eventFilter = marketPlace.filters.ListOnMarketplace(
  //     null,
  //     null
  //   );
  //   const events = await marketPlace.queryFilter(eventFilter);
  //   const listId = events[0].args[0];
  //   await expect(marketPlace.bid(listId, 1200)).to.emit(
  //     marketPlace,
  //     "BidOnAuction"
  //   );
  // });
  /*  it("Should list on marketplace", async () => {
    const listOnMarketplace = await marketPlace.listOnMarketplace(
      NFT.address,
      "0",
      "1"
    );
    const info = await marketPlace.getListingDetails("0");
    console.log("info 0", info);
  }); */
})
