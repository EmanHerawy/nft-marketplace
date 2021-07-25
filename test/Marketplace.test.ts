// const { expect, use } = require("chai");
// const { Contract, utils, Wallet, BigNumber } = require("ethers");
// const { deployContract, MockProvider, solidity } = require("ethereum-waffle");

// const StartFiToken = require("../artifacts/contracts/StartFiToken.sol/StartFiToken.json");
// const StartFiRoyaltyNFT = require("../artifacts/contracts/StartfiRoyaltyNFT.sol/StartfiRoyaltyNFT.json");
// const StartFiPaymentNFT = require("../artifacts/contracts/StartFiNFTPayment.sol/StartFiNFTPayment.json");
// const StartFiMarketPlace = require("../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json");
// const StartfiStakes = require("../artifacts/contracts/StartfiStakes.sol/StartfiStakes.json");
// const StartfiReputation = require("../artifacts/contracts/StartFiReputation.sol/StartFiReputation.json");

// use(solidity);

// describe("StartFi Marketplace", () => {
//   // let mockERC20
//   let startfiToken: any, startFiRoyaltyNFT : any, startFiPaymentNFT : any, startFiMarketplace : any;
//   let wallet : any;
//   let name = "Startfi";
//   let symbol = "STFI";
//   let baseUri = "http://ipfs.io";
//   beforeEach(async () => {
//     [wallet] = new MockProvider().getWallets();
//     startfiToken = await deployContract(wallet, StartFiToken, [
//       name,
//       symbol,
//       wallet.address,
//     ]);
//     startfiRoyaltyNFT = await deployContract(wallet, StartFiRoyaltyNFT, [
//       name,
//       symbol,
//       baseUri,
//     ]);
//     startFiPaymentNFT = await deployContract(wallet, StartFiPaymentNFT, [
//       startfiRoyaltyNFT.address,
//       startfiToken.address,
//     ]);
//     startfiStakes = await deployContract(wallet, StartfiStakes, [
//       startfiToken.address,
//     ]);
//     startfiReputation = await deployContract(wallet, StartfiReputation);
//     startFiMarketplace = await deployContract(wallet, StartFiMarketPlace, [
//       "StartFi Market",
//       startfiToken.address,
//       startfiStakes.address,
//       startfiReputation.address,
//     ]);
//     await startfiToken.approve(startFiMarketplace.address, 10000000000000);
//     await startfiRoyaltyNFT.grantRole(
//       "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",
//       startFiPaymentNFT.address
//     );
//     await startfiToken.approve(startFiPaymentNFT.address, 10000000000000);
//     await startfiToken.approve(startfiStakes.address, 10000000000000);

//     await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
//     await startFiPaymentNFT.MintNFTWithRoyalty(wallet.address, baseUri, 1, 10);
//     await startfiRoyaltyNFT.approve(startFiMarketplace.address, 0);
//     await startfiRoyaltyNFT.approve(startFiMarketplace.address, 1);
//   });

//   it("Should list on marketplace", async () => {
//     await expect(
//       startFiMarketplace.listOnMarketplace(startfiRoyaltyNFT.address, 0, 10)
//     ).to.emit(startFiMarketplace, "ListOnMarketplace");
//   });
//   it("ListOnMarketplace: Not enough reserves", async () => {
//     await expect(
//       startFiMarketplace.listOnMarketplace(startfiRoyaltyNFT.address, 2, 1000)
//     ).to.be.revertedWith("Not enough reserves");
//   });
//   it("ListOnMarketplace: revert Marketplace is not allowed to transfer your token", async () => {
//     await expect(
//       startFiMarketplace.listOnMarketplace(startFiPaymentNFT.address, 0, 20)
//     ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
//   });
//   it("Should create auction on marketplace", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startfiRoyaltyNFT.address,
//         0,
//         10,
//         11,
//         true,
//         11,
//         1000000000
//       )
//     ).to.emit(startFiMarketplace, "CreateAuction");
//   });
//   it("Auction: listing price should not equal zero", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startfiRoyaltyNFT.address,
//         0,
//         0,
//         11,
//         true,
//         2000,
//         1000000000
//       )
//     ).to.be.revertedWith("Zero Value is not allowed");
//   });
//   it("Auction: sell for price should not equal zero", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startfiRoyaltyNFT.address,
//         0,
//         10,
//         11,
//         true,
//         0,
//         1000000000
//       )
//     ).to.be.revertedWith("Zero price is not allowed");
//   });
//   it("Auction: Zero price is not allowed", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startfiRoyaltyNFT.address,
//         0,
//         10,
//         11,
//         true,
//         0,
//         1000000000
//       )
//     ).to.be.revertedWith("Zero price is not allowed");
//   });
//   it("Auction: Marketplace is not allowed to transfer your token", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startFiPaymentNFT.address,
//         0,
//         10,
//         11,
//         true,
//         11,
//         1000000000
//       )
//     ).to.be.revertedWith("Marketplace is not allowed to transfer your token");
//   });
//   it("Auction should live for more than 12 hours", async () => {
//     await expect(
//       startFiMarketplace.createAuction(
//         startfiRoyaltyNFT.address,
//         0,
//         10,
//         11,
//         true,
//         11,
//         10
//       )
//     ).to.be.revertedWith("Auction should be live for more than 12 hours");
//   });

//   it("Should bid item", async () => {
//     await startfiStakes.deposit(wallet.address, 1000);
//     await startFiMarketplace.listOnMarketplace(
//       startfiRoyaltyNFT.address,
//       1,
//       10
//     );
//     const eventFilter = startFiMarketplace.filters.ListOnMarketplace(
//       null,
//       null
//     );
//     const events = await startFiMarketplace.queryFilter(eventFilter);
//     const listId = events[0].args[0];
//     await expect(startFiMarketplace.bid(listId, 1200)).to.emit(
//       startFiMarketplace,
//       "BidOnAuction"
//     );
//   });
//   /*  it("Should list on marketplace", async () => {
//     const listOnMarketplace = await startFiMarketplace.listOnMarketplace(
//       startfiRoyaltyNFT.address,
//       "0",
//       "1"
//     );
//     const info = await startFiMarketplace.getListingDetails("0");
//     console.log("info 0", info);
//   }); */
// });
