// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
  const {deploy,get,execute} = deployments;
  const {deployer} = await getNamedAccounts();


  await deploy('StartFiReputation', {
    from: deployer,
    log: true,
  });
    };
module.exports.tags = ['StartFiReputation'];
