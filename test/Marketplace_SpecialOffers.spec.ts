import chai, { expect } from 'chai'
import { Contract, BigNumber } from 'ethers'

import { waffle } from 'hardhat'
const { solidity, deployContract, createFixtureLoader, provider } = waffle
import StartFiMarketPlace from '../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json'

import { tokenFixture } from './shared/fixtures'
/**
 * scenarios
 *  we might have some celebrities or big names who come to our platform though agreement, those users might need different terms and conditions and to enforce the agreement via smart contract we store them the contract and apply them in their deals  .
 *
 *
 */
chai.use(solidity)
const TEST_AMOUNT = 100000000 //expandTo18Decimals(10)
let NFT: Contract
let marketPlace: Contract
let reputation: Contract
let stakes: Contract

const _feeFraction = 25 // 2.5% fees
const _feeBase = 10

const royaltyShare = 25
const royaltyBase = 10
let marketplaceTokenId1: string
let listingId1: string
let listingId2: string
let price1 = 1000
let insuranceAmount = 10
let minimumBid = 10
let duration = 60 * 60 * 15 // 15 hours
let isForSale = false
let forSalePrice = 10000
const calcFees = (price: number, share: number, base: number): number => {
  // round decimal to the nearst value
  const _base = base * 100
  return price * (share / _base)
}
describe('StartFi marketPlace Sprciall offers : special Offers with fixed prices', () => {
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,
      _fee: 30, // 2.5% fees

      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    stakes = fixture.stakes

    marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,

      admin.address,
      10000,
      50000,
      5,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)

    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null)
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1 = (events[events.length - 1] as any).args[2].toNumber()
    console.log(marketplaceTokenId1, 'marketplaceTokenId1')
  })

  it('non admin can not add special offer ', async () => {
    await expect(
      marketPlace.addOffer(
        offers[0].wallet,
        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.be.revertedWith('caller is not the owner')
  })
  it('admin can  add special offer ', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,
        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    )
      .to.emit(marketPlace, 'NewOffer')
      .withArgs(
        admin.address,
        offers[0].wallet,
        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
  })
  it('No duplicated special offer allowed', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,
        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.revertedWith('Already exisit')
  })

  it('Special offer Should list on marketplace only using the deal terms', async () => {
    await expect(
      marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)
    ).to.be.revertedWith('Marketplace is not allowed to transfer your token')
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]
  })

  it('user can buy  an item on marketplace  using the offer terms', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, price1)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT - price1)
    const platformShare = Math.round(calcFees(price1, offers[0]._fee, offers[0]._feeBase))
    const platformWrongShare = Math.round(calcFees(price1, _feeFraction, _feeBase))
    console.log(platformShare, platformWrongShare, 'shares')

    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(price1 - platformShare)
    expect(await token.balanceOf(admin.address)).to.not.eq(platformWrongShare)
    expect(await token.balanceOf(issuer.address)).to.not.eq(price1 - platformWrongShare)
    // check balance
    // check balance
  })
})
describe('StartFi marketPlace : special Offers with fixed prices issuer deList with special terms', () => {
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,

      _fee: 30, // 2.5% fees

      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    stakes = fixture.stakes

    marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,

      admin.address,
      10000,
      50000,
      5,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)

    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null)
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1 = (events[events.length - 1] as any).args[2].toNumber()
    console.log(marketplaceTokenId1, 'marketplaceTokenId1')
  })

  it('non admin can not add special offer ', async () => {
    await expect(
      marketPlace.addOffer(
        offers[0].wallet,
        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.be.revertedWith('caller is not the owner')
  })
  it('admin can  add special offer ', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    )
      .to.emit(marketPlace, 'NewOffer')
      .withArgs(
        admin.address,
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
  })
  it('No duplicated special offer allowed', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.revertedWith('Already exisit')
  })

  // delist and lost reserves
  it('Should delist item ', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]

    await expect(marketPlace.connect(issuer).deList(listingId1)).to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(issuer.address)
  })
  it('Can not delist already de listed item ', async () => {
    await expect(marketPlace.connect(issuer).deList(listingId1)).to.revertedWith(
      'Item is not on Auction or Listed for sale'
    )
  })
  it('non owner can not delist ', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(marketPlace.connect(issuer).listOnMarketplace(NFT.address, marketplaceTokenId1, price1)).to.emit(
      marketPlace,
      'ListOnMarketplace'
    )
    const eventFilter = await marketPlace.filters.ListOnMarketplace(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId2 = (events[events.length - 1] as any).args[0]
    await expect(marketPlace.connect(wallet).deList(listingId2)).to.revertedWith('Caller is not the owner')
  })
  // delist
  it('Should delist item without losing stakes', async () => {
    const stakeAllowance = await stakes.getReserves(issuer.address)
    const listingDetails = await marketPlace.getListingDetails(listingId2)

    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()])
    await provider.send('evm_mine', [])
    await expect(marketPlace.connect(issuer).deList(listingId2)).to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(issuer.address)

    const newStakeAllowance = await marketPlace.getStakeAllowance(issuer.address)

    expect(newStakeAllowance.toNumber()).to.eq(stakeAllowance)
  })
})
describe('StartFi marketPlace : special Offers with Auction bid and buy', () => {
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,

      _fee: 30, // 2.5% fees

      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    stakes = fixture.stakes

    marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,

      admin.address,
      10000,
      50000,
      5,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)

    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null)
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1 = (events[events.length - 1] as any).args[2].toNumber()
    console.log(marketplaceTokenId1, 'marketplaceTokenId1')
  })

  it('non admin can not add special offer ', async () => {
    await expect(
      marketPlace.addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.be.revertedWith('caller is not the owner')
  })
  it('admin can  add special offer ', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    )
      .to.emit(marketPlace, 'NewOffer')
      .withArgs(
        admin.address,
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
  })
  it('No duplicated special offer alowed', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.revertedWith('Already exisit')
  })

  it('Special offer Should create auction only using the deal terms', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(
      marketPlace.connect(issuer).createAuction(
        NFT.address,
        marketplaceTokenId1,

        minimumBid,
        insuranceAmount,
        !isForSale,
        forSalePrice,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]
  })

  it('user can buy  an item on marketplace  using the offer terms', async () => {
    await expect(token.connect(user1).approve(marketPlace.address, forSalePrice)).to.emit(token, 'Approval')
    await expect(marketPlace.connect(user1).buyNow(listingId1)).to.emit(marketPlace, 'BuyNow')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(user1.address)
    expect(await token.balanceOf(user1.address)).to.eq(TEST_AMOUNT - forSalePrice)
    const platformShare = Math.round(calcFees(forSalePrice, offers[0]._fee, offers[0]._feeBase))
    const platformWrongShare = Math.round(calcFees(forSalePrice, _feeFraction, _feeBase))
    console.log(platformShare, platformWrongShare, 'shares')

    expect(await token.balanceOf(admin.address)).to.eq(platformShare)
    expect(await token.balanceOf(issuer.address)).to.eq(forSalePrice - platformShare)
    expect(await token.balanceOf(admin.address)).to.not.eq(platformWrongShare)
    expect(await token.balanceOf(issuer.address)).to.not.eq(forSalePrice - platformWrongShare)
    // check balance
    // check balance
  })
})
describe('StartFi marketPlace : special Offers with Auction bid only', () => {
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,
      _fee: 30, // 2.5% fees

      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    stakes = fixture.stakes

    marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,

      admin.address,
      10000,
      50000,
      5,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)

    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null)
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1 = (events[events.length - 1] as any).args[2].toNumber()
    console.log(marketplaceTokenId1, 'marketplaceTokenId1')
  })

  it('non admin can not add special offer ', async () => {
    await expect(
      marketPlace.addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.be.revertedWith('caller is not the owner')
  })
  it('admin can  add special offer ', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    )
      .to.emit(marketPlace, 'NewOffer')
      .withArgs(
        admin.address,
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
  })
  it('No duplicated special offer alowed', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.revertedWith('Already exisit')
  })

  it('Special offer Should create auction only using the deal terms', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(
      marketPlace.connect(issuer).createAuction(
        NFT.address,
        marketplaceTokenId1,

        minimumBid,
        insuranceAmount,
        isForSale,
        forSalePrice,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]
  })

  it('deposit stakes', async () => {
    const stakeAmount = insuranceAmount

    await expect(token.approve(stakes.address, stakeAmount))
      .to.emit(token, 'Approval')
      .withArgs(wallet.address, stakes.address, stakeAmount)
    expect(await token.allowance(wallet.address, stakes.address)).to.eq(stakeAmount)

    await stakes.deposit(wallet.address, stakeAmount)
    const reserves = await stakes.getReserves(wallet.address)
    expect(reserves.toNumber()).to.eq(stakeAmount)

    const stakeAllowance = await marketPlace.getStakeAllowance(wallet.address)
    expect(stakeAllowance.toNumber()).to.eq(stakeAmount)
  })
  it('Should  bid on item with price equal or more than the mini bid price', async () => {
    await expect(marketPlace.bid(listingId1, minimumBid + 1000)).to.emit(marketPlace, 'BidOnAuction')
  })
  it('Should  fulfill auction when ended after allowing token to pay', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1)

    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()])
    await provider.send('evm_mine', [])
    const winnerBid = await marketPlace.winnerBid(listingId1)

    await expect(token.approve(marketPlace.address, winnerBid.bidPrice)).to.emit(token, 'Approval')
    await expect(marketPlace.fulfillBid(listingId1)).to.emit(marketPlace, 'FulfillBid')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(wallet.address)
    const platformShare = Math.round(calcFees(winnerBid.bidPrice, offers[0]._fee, offers[0]._feeBase))
    const platformWrongShare = Math.round(calcFees(winnerBid.bidPrice, _feeFraction, _feeBase))
    console.log(platformShare, platformWrongShare, 'shares')

    expect(await token.balanceOf(admin.address)).to.eq(BigNumber.from(platformShare))
    expect(await token.balanceOf(issuer.address)).to.eq(BigNumber.from(winnerBid.bidPrice - platformShare))
    expect(await token.balanceOf(admin.address)).to.not.eq(BigNumber.from(platformWrongShare))
    expect(await token.balanceOf(issuer.address)).to.not.eq(BigNumber.from(winnerBid.bidPrice - platformWrongShare))
  })
})
describe('StartFi marketPlace : special Offers with Auction then delist', () => {
  const [wallet, user1, user2, user3, issuer, admin] = provider.getWallets()
  const loadFixture = createFixtureLoader([wallet])
  const offers = [
    {
      wallet: issuer.address,
      _fee: 30, // 2.5% fees

      _feeBase: 10,
    },
  ]
  let token: Contract
  before(async () => {
    const fixture = await loadFixture(tokenFixture)
    token = fixture.token
    NFT = fixture.NFT
    reputation = fixture.reputation
    stakes = fixture.stakes

    marketPlace = await deployContract(wallet, StartFiMarketPlace, [
      'StartFi Market',
      token.address,
      stakes.address,

      admin.address,
      10000,
      50000,
      5,
    ])

    // add to minter role
    await reputation.grantRole(
      '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',
      marketPlace.address
    )

    await stakes.setMarketplace(marketPlace.address)
    // the 3 user need to get balance

    await token.transfer(user1.address, TEST_AMOUNT)
    await token.transfer(user2.address, TEST_AMOUNT)
    await token.transfer(user3.address, TEST_AMOUNT)

    /// issuer mint NFT to test changed balance
    let baseUri = 'http://ipfs.io'
    await NFT.mintWithRoyalty(issuer.address, baseUri, royaltyShare, royaltyBase)
    const eventFilter = await NFT.filters.Transfer(null, null)
    const events = await NFT.queryFilter(eventFilter)
    marketplaceTokenId1 = (events[events.length - 1] as any).args[2].toNumber()
    console.log(marketplaceTokenId1, 'marketplaceTokenId1')
  })

  it('non admin can not add special offer ', async () => {
    await expect(
      marketPlace.addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.be.revertedWith('caller is not the owner')
  })
  it('admin can  add special offer ', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    )
      .to.emit(marketPlace, 'NewOffer')
      .withArgs(
        admin.address,
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
  })
  it('No duplicated special offer alowed', async () => {
    await expect(
      marketPlace.connect(admin).addOffer(
        offers[0].wallet,

        offers[0]._fee, // 2.5% fees

        offers[0]._feeBase
      )
    ).to.revertedWith('Already exisit')
  })

  it('Special offer Should create auction only using the deal terms', async () => {
    await expect(NFT.connect(issuer).approve(marketPlace.address, marketplaceTokenId1))
      .to.emit(NFT, 'Approval')
      .withArgs(issuer.address, marketPlace.address, marketplaceTokenId1)
    expect(await NFT.getApproved(marketplaceTokenId1)).to.eq(marketPlace.address)
    await expect(
      marketPlace.connect(issuer).createAuction(
        NFT.address,
        marketplaceTokenId1,

        minimumBid,
        insuranceAmount,
        isForSale,
        forSalePrice,
        duration
      )
    ).to.emit(marketPlace, 'CreateAuction')
    const eventFilter = await marketPlace.filters.CreateAuction(null, null)
    const events = await marketPlace.queryFilter(eventFilter)
    listingId1 = (events[events.length - 1] as any).args[0]
  })

  it('Should  delist auction when ended with special terms', async () => {
    const listingDetails = await marketPlace.getListingDetails(listingId1)

    await provider.send('evm_increaseTime', [listingDetails.releaseTime.toNumber()])
    await provider.send('evm_mine', [])

    await expect(marketPlace.connect(issuer).deList(listingId1)).to.emit(marketPlace, 'DeListOffMarketplace')
    expect(await NFT.ownerOf(marketplaceTokenId1)).to.eq(issuer.address)
  })
})
