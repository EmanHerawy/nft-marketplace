// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    let name="StartFiToken",symbol="STFI"
    await deploy('StartFiToken', {
      from: deployer,
      args: [name,symbol,deployer],
      log: true,
    });
  };
  module.exports.tags = ['StartFiToken'];