// deploy/00_deploy_my_contract.js
module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    let name="StartFiNFTToken",symbol="STFI", base_uri="http://ipfs.io"
    await deploy('StartFiRoyaltyNFT', {
      from: deployer,
      args: [name,symbol,base_uri],
      log: true,
    });
  };
  module.exports.tags = ['StartFiRoyaltyNFT'];