// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get} = deployments;
    const {deployer} = await getNamedAccounts();
    let stfi_token= await get('StartFiToken');

    await deploy('StartfiStakes', {
      from: deployer,
      args: [stfi_token.address],
      log: true,
    });
  };
  module.exports.tags = ['StartfiStakes'];