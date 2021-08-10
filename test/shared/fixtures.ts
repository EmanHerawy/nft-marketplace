import { Contract, Wallet, providers } from 'ethers'
import { deployContract, MockProvider } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

import ERC20 from "../../artifacts/contracts/StartFiToken.sol/StartFiToken.json";
import StartFiRoyaltyNFT from "../../artifacts/contracts/StartfiRoyaltyNFT.sol/StartfiRoyaltyNFT.json";
import StartFiPaymentNFT from "../../artifacts/contracts/StartFiNFTPayment.sol/StartFiNFTPayment.json";
import StartFiMarketPlace from "../../artifacts/contracts/StartFiMarketPlace.sol/StartFiMarketPlace.json";
import StartfiStakes from "../../artifacts/contracts/StartfiStakes.sol/StartfiStakes.json";
import StartfiReputation from "../../artifacts/contracts/StartFiReputation.sol/StartFiReputation.json";
const { Web3Provider } = providers;
interface ContractsFixture {
  token: Contract,
  NFT: Contract,
  payment: Contract,
  marketPlace: Contract,
  reputation: Contract,
  stakes: Contract

}

const overrides = {
  gasLimit: 9999999
}
let baseUri = "http://ipfs.io";
const name = "StartFiToken";
const symbol = "STFI";
export async function tokenFixture( [wallet]: Wallet[],_: MockProvider,): Promise<ContractsFixture> {
  const token = await deployContract(wallet, ERC20, [name, symbol, wallet.address])
  const NFT = await deployContract(wallet, StartFiRoyaltyNFT, [name, symbol, baseUri])
  const stakes = await deployContract(wallet, StartfiStakes, [NFT.address])
  const payment = await deployContract(wallet, StartFiPaymentNFT, [NFT.address,token.address])
  const reputation = await deployContract(wallet, StartfiReputation)

  const marketPlace = await deployContract(wallet, StartFiMarketPlace, ["StartFi Market",token.address,stakes.address,reputation.address])


  // add to minter role 
  await reputation.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", NFT.address)
  await NFT.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", payment.address)
  // mint 4 tokens / 2 without royalty and 2 with royalty 
  await NFT.mint(wallet.address,baseUri)
  await NFT.mint(wallet.address,baseUri)
  await NFT.mintWithRoyalty(wallet.address,baseUri,25,10)
  await NFT.mintWithRoyalty(wallet.address,baseUri,25,10)
  await stakes.setMarketplace(marketPlace.address);
  return { token ,stakes,NFT, marketPlace,payment,reputation}
}

interface PairFixture extends ContractsFixture {
  token0: Contract
  token1: Contract
  pair: Contract
}

// export async function pairFixture(provider: MockProvider, [wallet]: Wallet[]): Promise<PairFixture> {
//   const { factory } = await factoryFixture(provider, [wallet])

//   const tokenA = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)])
//   const tokenB = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)])

//   await factory.createPair(tokenA.address, tokenB.address)
//   const pairAddress = await factory.getPair(tokenA.address, tokenB.address)
//   const pair = new Contract(pairAddress, JSON.stringify(UniswapV2Pair.abi), provider).connect(wallet)

//   const token0Address = (await pair.token0()).address
//   const token0 = tokenA.address === token0Address ? tokenA : tokenB
//   const token1 = tokenA.address === token0Address ? tokenB : tokenA

//   return { factory, token0, token1, pair }
// }
