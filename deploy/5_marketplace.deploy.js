// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get,execute} = deployments;
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');
    let stakesContract= await get('StartfiStakes');
    let payment= await get('StartFiNFTPayment');
    let nft_token= await get('StartfiRoyaltyNFT');

    await deploy('StartFiMarketPlace', {
      from: deployer,
      args: ["StartFi Market",stfi_token.address,stakesContract.address],
      log: true,
    });
     await execute('StartfiRoyaltyNFT',{from:deployer},'grantRole','0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6',payment.address)
    await execute('StartfiStakes',{from:deployer},'setMarketplace',nft_token.address)
   };
  module.exports.tags = ['StartFiMarketPlace'];