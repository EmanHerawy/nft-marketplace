// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get} = deployments;
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');
 
    await deploy('StartFiTokenDistribution', {
      from: deployer,
      args: [stfi_token.address,Date.now(),deployer],
      log: true,
    });
    await deploy('StartFiTokenDistributionV2', {
      from: deployer,
      args: [stfi_token.address,Date.now(),deployer],
      log: true,
    });
  };
  module.exports.tags = ['StartFiTokenDistribution','StartFiTokenDistributionV2'];