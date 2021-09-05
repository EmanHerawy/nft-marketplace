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


    await deploy('StartFiMarketPlace', {
      from: deployer,
      args: ["StartFi Market",stfi_token.address,stakesContract.address, startFi_reputation.address,deployer],
      log: true,
    });

    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mint',deployer,baseUri)
    //  await execute('StartFiRoyaltyNFT',{from:deployer},'mintWithRoyalty',deployer,baseUri,25,10)
    await execute('StartFiStakes',{from:deployer},'setMarketplace',nft_token.address)
   };
  module.exports.tags = ['StartFiMarketPlace'];