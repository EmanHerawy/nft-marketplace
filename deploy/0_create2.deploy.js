// deployed only one time per network
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    await deploy('StartfiCreate2Deployer', {
      from: deployer,
      args: [],
      log: true,
    });
  };
  module.exports.tags = ['StartfiCreate2Deployer'];