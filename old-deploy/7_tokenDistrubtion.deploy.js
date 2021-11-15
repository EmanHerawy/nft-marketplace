// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy,get} = deployments;
    const {deployer} = await getNamedAccounts();
 
  
    await deploy('StartFiTokenDistribution', {
      from: deployer,
      args: ["0xFD9cd8c0D18cD7e06958F3055e0Ec3ADbdba0B17",1629077453,"0x392e861c447929Cc01e309B41f0CA43BBFC33D7D"

      ],
      log: true,
    });
  };
  module.exports.tags = ['StartFiTokenDistributionV2'];