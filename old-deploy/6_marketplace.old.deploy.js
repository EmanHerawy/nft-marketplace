// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get,execute} = deployments;
    const baseUri="http://ipfs.io";
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');
    let stakesContract= await get('StartFiStakes');
     let nft_token= await get('StartFiRoyaltyNFT');
    let nftoken= await get('StartFiRoyaltyNFT');
    let startFi_reputation= await get('StartFiReputation');


 const startFiMarketPlace =   await deploy('StartFiMarketPlace', {
      from: deployer,
      args: ["StartFi Market",stfi_token.address,stakesContract.address, startFi_reputation.address,deployer],
      log: true,
    });

    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    await execute('StartFiStakes',{from:deployer},'setMarketplace',nft_token.address)
    await execute('StartFiReputation',{from:deployer},'grantRole',"0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6",startFiMarketPlace.address)
   };
  module.exports.tags = ['StartFiMarketPlace'];