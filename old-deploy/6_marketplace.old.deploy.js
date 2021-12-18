// deploy/00_deploy_my_contract.js
const expandTo18Decimals = require('../test/shared/utilities').expandTo18Decimals;

module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get,execute} = deployments;
    const baseUri="http://ipfs.io";
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');
    let stakesContract= await get('StartFiStakes');
      const _usdCap = expandTo18Decimals(20000);
  const _stfiCap = expandTo18Decimals(200000);
  const _stfiUsdt = expandTo18Decimals(10);
 

 const startFiMarketPlace =   await deploy('StartFiMarketPlace', {
      from: deployer,
      args: ["StartFi Market",stfi_token.address,stakesContract.address, deployer , _usdCap , _stfiCap , _stfiUsdt],
      log: true,
    });

    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    // await execute('StartFiStakes',{from:deployer},'setMarketplace',nft_token.address)
    // await execute('StartFiReputation',{from:deployer},'grantRole',"0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",startFiMarketPlace.address)
   };
  module.exports.tags = ['StartFiMarketPlace'];