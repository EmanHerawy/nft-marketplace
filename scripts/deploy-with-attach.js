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
  // const StartFiToken = await hre.ethers.getContractFactory("StartFiToken");
  // const StartFiRoyaltyNFT = await hre.ethers.getContractFactory("StartFiRoyaltyNFT");
  // const StartFiStakes = await hre.ethers.getContractFactory("StartFiStakes");
  const StartFiReputation = await hre.ethers.getContractFactory("StartFiReputation");
  // const StartFiMarketPlace = await hre.ethers.getContractFactory("StartFiMarketPlace");



  const startfiReputation = await StartFiReputation.attach("0xffEA8f772D129eF0A0AFd98b4c31814fe8579C09");
   // add to minter role 
   await startfiReputation.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6","0x1227A9E73233EF9453EFe35b3eeE02B6d0f294D9")
  

      //   const isERC721 = await startFiNFT.supportsInterface("0x01ffc9a7");
      // console.log(isERC721,'isERC721 ');
      // const isERCRoyalty = await startFiNFT.supportsInterface("0x2a55205a");
      // console.log(isERCRoyalty,'isERCRoyalty');
      
 
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
