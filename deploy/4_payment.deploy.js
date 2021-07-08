// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get} = deployments;
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');
    let nft_token= await get('StartfiRoyaltyNFT');

    await deploy('StartFiNFTPayment', {
      from: deployer,
      args: [nft_token.address,stfi_token.address],
      log: true,
    });
  };
  module.exports.tags = ['StartFiNFTPayment'];