const { hexlify, formatBytes32String } = require('ethers/lib/utils')

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const StartFiRoyaltyNFT = await ethers.getContractFactory('StartFiRoyaltyNFT')
  let StartfiCreate2Deployer = await ethers.getContractFactory('StartfiCreate2Deployer')
  const { get } = deployments
  const { deployer } = await getNamedAccounts()

  // let create2Deployer = await get('StartfiCreate2Deployer')

  let name = 'StartFiNFT',
    symbol = 'STFI'

  const constructorArgs = [name, symbol]

 let factoryAddress ="0x2BE72529eEcfa1136Ad3E9F4c34ad4bf0c73BcBB" //create2Deployer.address //'Tp be added' // if localhost , deploy first !

  const constructorTypes = ['string', 'string']
  const constructor = encodeParam(constructorTypes, constructorArgs).slice(2)
  const bytecode = `${StartFiRoyaltyNFT.bytecode}${constructor}`
const salt = formatBytes32String('Startfi2021')
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
console.log({bytecode,salt});
  // First see if already deployed
  const computedAddr = buildCreate2Address(factoryAddress, hexlify(salt), bytecode)
  console.log(computedAddr, 'computedAddr')
  const isDeployed = await isContract(computedAddr)
  if (!isDeployed) {
    const factory = await StartfiCreate2Deployer.attach(factoryAddress)
    const result = await (await factory.deploy(0, salt, bytecode,{nonce:6})).wait()
    // const addr = result.events[0].args.newAddress.toLowerCase()
    console.log({ result })
    // console.log({ addr })
  }
}

module.exports.tags = ['StartFiRoyaltyNFT']
