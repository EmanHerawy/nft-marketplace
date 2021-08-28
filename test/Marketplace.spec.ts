import chai, { expect } from 'chai'
import { Contract, constants, utils } from 'ethers'
import { ecsign } from 'ethereumjs-util'

const { MaxUint256 } = constants
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract, createFixtureLoader } from 'ethereum-waffle'

import { expandTo18Decimals, getApprovalDigest, getApprovalNftDigest } from './shared/utilities'

import { tokenFixture } from './shared/fixtures'
import { hexlify } from 'ethers/lib/utils'

chai.use(solidity)
const name = 'StartFiToken'
const symbol = 'STFI'
const TOTAL_SUPPLY = expandTo18Decimals(100000000)
const TEST_AMOUNT = expandTo18Decimals(10)
let token: Contract
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract
let marketplaceTokenId1 = 1
let marketplaceTokenId2 = 2
let marketplaceTokenId3 = 3
let auctionTokenId = 4
describe('StartFi marketPlace', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])

  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    marketPlace = fixture.marketPlace
    reputation = fixture.reputation
    stakes = fixture.stakes
  })


 
  it('ListOnMarketplace: Not enough reserves', async () => {
   
    await expect(marketPlace.listOnMarketplace(NFT.address, marketplaceTokenId1, 1000)).to.be.revertedWith(
      'Not enough reserves'
    )
  })
  it('deposit stakes', async () => {
    const stakeAmount =1000;
    await expect(token.approve(stakes.address, stakeAmount))
    .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)
  
    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)
   
    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address);
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('list on marketplace should not be allowed if marketplace is not approved', async () => {
    
    await expect(marketPlace.listOnMarketplace(NFT.address, marketplaceTokenId1, 10)).to.be.revertedWith(
      'Marketplace is not allowed to transfer your token'
    )
  })
  it('approve', async () => {
    await expect(NFT.approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(wallet.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
  })
  it('Should list on marketplace', async () => {
    
    await expect(marketPlace.listOnMarketplace(NFT.address, marketplaceTokenId1, 10)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
  })

  // it('Should list on marketplace:permit', async () => {
  //    await expect(
  //    await marketPlace._supportPremit(NFT.address)
  //   ).to.eql(true)
  // })
  it('Should list on marketplace:permit', async () => {
    const nonce = await NFT.nonces(wallet.address)
    const chainId = await NFT.getChainId()
     const deadline = MaxUint256
    const digest = await getApprovalNftDigest(
      NFT,
      { owner: wallet.address, spender: marketPlace.address, tokenId: marketplaceTokenId2 },
      nonce,
      deadline,
      chainId,
    )
    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))
    // await expect(NFT.permit(wallet.address, marketPlace.address, marketplaceTokenId2, deadline, v, hexlify(r), hexlify(s)))
    // .to.emit(NFT, 'Approval')
     await expect( await
      marketPlace.listOnMarketplaceWithPremit(NFT.address, marketplaceTokenId2, 10, deadline, v, hexlify(r), hexlify(s))
    ).to.emit(marketPlace, 'ListOnMarketplace')
  })
  it('Auction: Marketplace is not allowed to transfer your token', async () => {
    await expect(
      marketPlace.createAuction(NFT.address, auctionTokenId, 10, 11, true, 11, 1000000000)
    ).to.be.revertedWith('Marketplace is not allowed to transfer your token')
  })
  it('Auction: listing price should not equal zero', async () => {
    await expect(
      marketPlace.createAuction(NFT.address, auctionTokenId, 0, 11, true, 2000, 1000000000)
    ).to.be.revertedWith('Zero Value is not allowed')
  })

  it('Auction: Zero price is not allowed', async () => {
    await expect(
      marketPlace.createAuction(NFT.address, auctionTokenId, 10, 11, true, 0, 1000000000)
    ).to.be.revertedWith('Zero price is not allowed')
  })

  it('Auction: listing price should not equal zero', async () => {
    await expect(
      marketPlace.createAuction(NFT.address, auctionTokenId, 0, 11, true, 2000, 1000000000)
    ).to.be.revertedWith('Zero Value is not allowed')
  })
  it('Auction: sell for price should not equal zero', async () => {
    await expect(
      marketPlace.createAuction(NFT.address, auctionTokenId, 10, 11, true, 0, 1000000000)
    ).to.be.revertedWith('Zero price is not allowed')
  })

  it('Auction should live for more than 12 hours', async () => {
    await expect(marketPlace.createAuction(NFT.address, auctionTokenId, 10, 11, true, 11, 10)).to.be.revertedWith(
      'Auction should be live for more than 12 hours'
    )
  })
  // it('Auction: Should create auction on marketplace', async () => {
  //   await NFT.approve(marketPlace.address, auctionTokenId)
  //   await expect(marketPlace.createAuction(NFT.address, auctionTokenId, 10, 11, true, 11, 1000000000)).to.emit(
  //     marketPlace,
  //     'CreateAuction'
  //   )
  // })
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
