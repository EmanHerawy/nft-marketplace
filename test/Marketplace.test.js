const { expect, use } = require("chai");
const { Contract, utils, Wallet, BigNumber } = require("ethers");
const { deployContract, MockProvider, solidity } = require("ethereum-waffle");
const { formatBytes32String } = require("ethers/lib/utils");

// const IERC20 = require( "../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json")
const StartFiToken = require("../artifacts/contracts/StartFiToken.sol/StartFiToken.json");
const StartFiRoyaltyNFT = require("../artifacts/contracts/StartfiRoyaltyNFT.sol/StartfiRoyaltyNFT.json");
const StartFiPaymentNFT = require("../artifacts/contracts/StartFiNFTPayment.sol/StartFiNFTPayment.json");
const StartFiMarketPlace = require("../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json");
const StartfiStakes = require("../artifacts/contracts/StartfiStakes.sol/StartfiStakes.json");
const StartfiReputation = require("../artifacts/contracts/StartFiReputation.sol/StartFiReputation.json");

use(solidity);

describe("StartFi Marketplace", () => {
  // let mockERC20
  let startfiToken, startFiRoyaltyNFT, startFiPaymentNFT, startFiMarketplace;
  let wallet;
  let name = "Startfi";
  let symbol = "STFI";
  let baseUri = "http://ipfs.io";
  beforeEach(async () => {
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
    startFiMarketplace = await deployContract(wallet, StartFiMarketPlace, [
      "StartFi Market",
      startfiToken.address,
      startfiStakes.address,
      startfiReputation.address,
    ]);
    await startfiToken.approve(startFiMarketplace.address, 10000000000000);
    await startfiRoyaltyNFT.grantRole(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
      startFiPaymentNFT.address
    );
    await startfiToken.approve(startFiPaymentNFT.address, 10000000000000);
    await startfiToken.approve(startfiStakes.address, 10000000000000);

    await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
    await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
    await startfiRoyaltyNFT.approve(startFiMarketplace.address, 0);
    await startfiRoyaltyNFT.approve(startFiMarketplace.address, 1);
  });

  it("Should list on marketplace", async () => {
   // await startfiStakes.deposit(wallet.address,10000)
    const listOnMarketplace_first = await startFiMarketplace.listOnMarketplace(startfiRoyaltyNFT.address, 0, 10);
    console.log('listOnMarketplace_first listingId', listOnMarketplace_first)
    const listOnMarketplace_second = await startFiMarketplace.listOnMarketplace(
      startfiRoyaltyNFT.address,
      1,
      10
    );
    console.log("listOnMarketplace_second listingId", listOnMarketplace_second);
    /* console.log("real value is", listOnMarketplace.value.toNumber());
    console.log("0", formatBytes32String("0"));
    console.log("1", formatBytes32String("1"));
    console.log("100000", formatBytes32String("100000")); 

    const info = await startFiMarketplace.getListingDetails(
      "0x3000000000000000000000000000000000000000000000000000000000000000"
    );
    console.log("info 0", info);
    /*const info_1 = await startFiMarketplace.getListingDetails(formatBytes32String("100000"));
    console.log("info 1", info_1); */
    // expect(info.tokenAddress).to.be.equal(wallet.address);*/
  });
 /*  it("Should create auction on marketplace", async () => {
    const createAuction = await startFiMarketplace.createAuction(
      startfiRoyaltyNFT.address,
      0,
      10,
      11,
      true,
      11,
      1000000000
    );
    expect(createAuction.from).to.be.equal(wallet.address);
  }); */
  /*   it("Should bid item", async () => {
    await startFiMarketplace.createAuction(
      startfiRoyaltyNFT.address,
      "0",
      "10",
      "11",
      "true",
      "11",
      "10000000"
    );
    const bid = await startFiMarketplace.bid(
      formatBytes32String("0"),
      startfiStakes.address,
      "0",
      "1"
    );
    expect(bid.from).to.be.equal(wallet.address);
  }); */
  /*  it("Should list on marketplace", async () => {
    const listOnMarketplace = await startFiMarketplace.listOnMarketplace(
      startfiRoyaltyNFT.address,
      "0",
      "1"
    );
    const info = await startFiMarketplace.getListingDetails("0");
    console.log("info 0", info);
  }); */
});
