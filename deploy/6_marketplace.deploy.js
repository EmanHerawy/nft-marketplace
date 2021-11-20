const { hexlify, formatBytes32String } = require('ethers/lib/utils')
const contracts = require('../deployments/computedAddreses.json')

// deploy/00_deploy_my_contract.js
module.exports = async ({ deployments, getNamedAccounts }) => {
  const StartFiMarketPlace = await ethers.getContractFactory('StartFiMarketPlace')
  let StartfiCreate2Deployer = await ethers.getContractFactory('StartfiCreate2Deployer')
  let StartFiStakes = await ethers.getContractFactory('StartFiStakes')
  let StartFiReputation = await ethers.getContractFactory('StartFiReputation')
  const { get, execute } = deployments
  const { deployer } = await getNamedAccounts()
  const _usdCap = 10000
  const _stfiCap = 50000
  const _stfiUsdt = 5
  let create2Deployer = await get('StartfiCreate2Deployer')
  // let stfi_token= await get('StartFiToken');
  //   let stakesContract= await get('StartFiStakes');
  //    let nft_token= await get('StartFiRoyaltyNFT');
  //   let nftoken= await get('StartFiRoyaltyNFT');
  //   let startFi_reputation= await get('StartFiReputation');

  const constructorArgs = ['StartFi Market', contracts.stfiToken, contracts.staking, deployer , _usdCap , _stfiCap , _stfiUsdt ]
  // const constructorArgs = ["StartFi Market",stfi_token.address,stakesContract.address, startFi_reputation.address,deployer]

  // 0x19550457F532A47f8B64e1246563e9013DF20260
  // let factoryAddress = "0x19550457F532A47f8B64e1246563e9013DF20260"; // if localhost , deploy first !
  let factoryAddress = create2Deployer.address //'Tp be added' // if localhost , deploy first !

  // if (network.name == `hardhat` || network.name == `localhost`) {
  //   const factoryDeployed = await deploy('AnyNFTCreate2Deployer', {
  //     from: deployer,
  //     args: [],
  //     log: true,
  //   })
  //   factoryAddress = factoryDeployed.address

  //   console.log(factoryAddress, 'factoryAddress')
  // }
  const constructorTypes = ['string', 'address', 'address', 'address', 'uint256', 'uint256', 'uint256']
  // console.log(StartFiMarketPlace.bytecode,'StartFiMarketPlace.bytecode');
  const constructor = encodeParam(constructorTypes, constructorArgs).slice(2)
  const bytecode = `${StartFiMarketPlace.bytecode}${constructor}`
  // const bytecode = `${optimizedbytecode}${constructor}`
  const salt = formatBytes32String('Startfi2021')
  // console.log({bytecode});
  // console.log({salt});
  // encodes parameter to pass as contract argument
  function encodeParam(dataType, data) {
    const abiCoder = ethers.utils.defaultAbiCoder
    return abiCoder.encode(dataType, data)
  }

  function buildCreate2Address(creatorAddress, saltHex, byteCode) {
    return `0x${ethers.utils
      .keccak256(
        `0x${['ff', creatorAddress, saltHex, ethers.utils.keccak256(byteCode)]
          .map((x) => x.replace(/0x/, ''))
          .join('')}`
      )
      .slice(-40)}`.toLowerCase()
  }

  // returns true if contract is deployed on-chain
  async function isContract(address) {
    const code = await ethers.provider.getCode(address)
    return code.slice(2).length > 0
  }

  // First see if already deployed
  const computedAddr = buildCreate2Address(factoryAddress, hexlify(salt), bytecode)
  console.log(computedAddr, 'computedAddr')
  const isDeployed = await isContract(computedAddr)
  if (!isDeployed) {
    const factory = await StartfiCreate2Deployer.attach(factoryAddress)
    const result = await (await factory.deploy(0, salt, bytecode)).wait()
    // const addr = result.events[0].args.newAddress.toLowerCase()
    console.log({ result })
    // console.log({ addr })
  }

  const staking = await StartFiStakes.attach(contracts.staking)
  await (await staking.setMarketplace(contracts.nft)).wait()
  const reputation = await StartFiReputation.attach(contracts.reputation)
  await (
    await reputation.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', computedAddr)
  ).wait()
}

module.exports.tags = ['StartFiMarketPlace']
