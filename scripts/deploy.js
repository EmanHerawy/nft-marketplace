// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const accounts = await ethers.getSigners();
   let name="StartFiToken",symbol="STFI",initialSupply,owner =accounts[0].address;
console.log(owner,'owner');

/*******************************get Artifacts ******************************* */ 
  const StartFiToken = await hre.ethers.getContractFactory("StartFiToken");
  const StartfiRoyaltyNFT = await hre.ethers.getContractFactory("StartfiRoyaltyNFT");
  const StartfiStakes = await hre.ethers.getContractFactory("StartfiStakes");
  const StartFiNFTPayment = await hre.ethers.getContractFactory("StartFiNFTPayment");
  const StartfiMarketPlace = await hre.ethers.getContractFactory("StartFiMarketPlace");



  const startFiToken = await StartFiToken.deploy(name,symbol,owner);
  await startFiToken.deployed();
  console.log("StartFiToken deployed to:", startFiToken.address);

  const startFiNFT = await StartfiRoyaltyNFT.deploy(name,  symbol,   "http://ipfs.io");
  await startFiNFT.deployed();

  console.log("startFiNFT deployed to:", startFiNFT.address);

  const startFiStakes = await StartfiStakes.deploy(startFiToken.address);
  await startFiStakes.deployed();
  console.log("startFiStakes deployed to:", startFiStakes.address);

const startFiNFTPayment=  await StartFiNFTPayment.deploy(startFiNFT.address, startFiToken.address);
await startFiNFTPayment.deployed();
console.log("startFiNFTPayment deployed to:", startFiNFTPayment.address);


const startfiMarketPlace=  await StartfiMarketPlace.deploy("Test ERC721",  startFiToken.address,startFiStakes.address);
await startfiMarketPlace.deployed();
console.log("startfiMarketPlace deployed to:", startfiMarketPlace.address);

   // add to minter role 
   await startFiNFT.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",startFiNFTPayment.address)
       await startFiStakes.setMarketplace(startfiMarketPlace.address);
 
        const isERC721 = await startFiNFT.supportsInterface("0x01ffc9a7");
      console.log(isERC721,'isERC721 ');
      const isERCRoyalty = await startFiNFT.supportsInterface("0x2a55205a");
      console.log(isERCRoyalty,'isERCRoyalty');
      
 
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
