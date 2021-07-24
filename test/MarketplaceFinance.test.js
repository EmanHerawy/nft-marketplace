const { expect, use } = require("chai");
const { Contract, utils, Wallet, BigNumber } = require("ethers");
const { deployContract, MockProvider, solidity } = require("ethereum-waffle");

const StartFiToken = require("../artifacts/contracts/StartFiToken.sol/StartFiToken.json");
const StartFiRoyaltyNFT = require("../artifacts/contracts/StartfiRoyaltyNFT.sol/StartfiRoyaltyNFT.json");
const StartFiPaymentNFT = require("../artifacts/contracts/StartFiNFTPayment.sol/StartFiNFTPayment.json");
const StartFiMarketPlaceFinance = require("../artifacts/contracts/StartfiMarketPlaceFinance.sol/StartfiMarketPlaceFinance.json");
const StartfiStakes = require("../artifacts/contracts/StartfiStakes.sol/StartfiStakes.json");
const StartfiReputation = require("../artifacts/contracts/StartFiReputation.sol/StartFiReputation.json");

use(solidity);

describe("StartFi Marketplace Finance", () => {
  let startfiToken,
    startFiRoyaltyNFT,
    startFiPaymentNFT,
    startFiMarketplaceFinance;
  let wallet, wallets;
  let name = "Startfi";
  let symbol = "STFI";
  let baseUri = "http://ipfs.io";
  beforeEach(async () => {
    wallets = new MockProvider().getWallets();
    [wallet] = new MockProvider().getWallets();
    startfiToken = await deployContract(wallet, StartFiToken, [
      name,
      symbol,
      wallet.address,
    ]);
    startfiRoyaltyNFT = await deployContract(wallet, StartFiRoyaltyNFT, [
      name,
      symbol,
      baseUri,
    ]);
    startFiPaymentNFT = await deployContract(wallet, StartFiPaymentNFT, [
      startfiRoyaltyNFT.address,
      startfiToken.address,
    ]);
    startfiStakes = await deployContract(wallet, StartfiStakes, [
      startfiToken.address,
    ]);
    startfiReputation = await deployContract(wallet, StartfiReputation);
    startFiMarketplaceFinance = await deployContract(
      wallet,
      StartFiMarketPlaceFinance,
      ["StartFi Market", startfiToken.address, startfiReputation.address]
    );
    await startfiToken.approve(
      startFiMarketplaceFinance.address,
      10000000000000
    );
    await startfiRoyaltyNFT.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiPaymentNFT.address
    );
    await startfiReputation.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiMarketplaceFinance.address
    );
    await startfiToken.approve(startFiPaymentNFT.address, 10000000000000);
    await startfiToken.approve(startfiStakes.address, 10000000000000);

    await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
    await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
    await startfiRoyaltyNFT.approve(startFiMarketplaceFinance.address, 0);
    await startfiRoyaltyNFT.approve(startFiMarketplaceFinance.address, 1);
  });

  it("Should pay fin", async () => {
    const deduct = await startFiMarketplaceFinance._deduct(
      wallet.address,
      wallets[1].address,
      10
    );
    console.log({ deduct });
    expect(deduct.from).to.eq(wallet.address);
  });
  it("add reputation point", async () => {
    const points = await startFiMarketplaceFinance._addreputationPoints(
      wallet.address,
      wallets[1].address,
      10
    );
    expect(points.from).to.eq(wallet.address);
  });
  it("safe transfer/ from", async () => {
    const transferer = await startFiMarketplaceFinance._safeTokenTransfer(
      wallets[1].address,
      1
    );
    const transfererFrom = await startFiMarketplaceFinance._safeTokenTransferFrom(
      wallet.address,
      wallets[1].address,
      1
    );
    expect(transfererFrom.from).to.eq(wallet.address);
  });
  it("set reserve", async () => {
    const reserve = await startFiMarketplaceFinance._setUserReserves(
      wallets[1].address,
      1
    );
    expect(reserve.from).to.eq(wallet.address);
  });
  it("update reserve", async () => {
    const addReserve = await startFiMarketplaceFinance._updateUserReserves(
      wallets[1].address,
      1,
      true
    );
    const subReserve = await startFiMarketplaceFinance._updateUserReserves(
      wallets[1].address,
      1,
      true
    );
    expect(addReserve.from).to.eq(wallet.address);
    expect(subReserve.from).to.eq(wallet.address);
  });
  it("change fees", async () => {
    const changeFees = await startFiMarketplaceFinance.changeFees(20, 1000);
    expect(changeFees.from).to.eq(wallet.address);
  });
  it("change utility token", async () => {
    const utilityToken = await startFiMarketplaceFinance._changeUtiltiyToken(
      startfiToken.address
    );
    expect(utilityToken.from).to.eq(wallet.address);
  });
  it("change reputation token", async () => {
    const utilityToken = await startFiMarketplaceFinance._changeReputationContract(
      startfiToken.address
    );
    expect(utilityToken.from).to.eq(wallet.address);
  });
  it("change bid Penalty Percentage", async () => {
    const penalty = await startFiMarketplaceFinance._changeBidPenaltyPercentage(
      35,
      1000
    );
    expect(penalty.from).to.eq(wallet.address);
  });
  it("change delist fees Percentage", async () => {
    const delistFees = await startFiMarketplaceFinance._changeDelistFeesPerentage(
      20,
      1000
    );
    expect(delistFees.from).to.eq(wallet.address);
  });
  it("change qualify amount", async () => {
    const qualifyAmount = await startFiMarketplaceFinance._changeListqualifyAmount(
      30,
      1000
    );
    console.log({ qualifyAmount });
    expect(qualifyAmount.from).to.eq(wallet.address);
  });
});
