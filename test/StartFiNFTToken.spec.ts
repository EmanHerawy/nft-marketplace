import chai, { expect } from 'chai'
import { Contract, constants, utils,BigNumber, Wallet } from 'ethers'
const { MaxUint256 } = constants;
// BigNumber.from
// import { bigNumberify, hexlify, keccak256, defaultAbiCoder, toUtf8Bytes } from 'ethers/utils'
import { solidity, MockProvider, deployContract } from 'ethereum-waffle'
import { ecsign } from 'ethereumjs-util'
 const {
 
  keccak256,
  hexlify,
  defaultAbiCoder,
  toUtf8Bytes,
  solidityPack
} = utils

import { expandTo18Decimals,  getApprovalNftDigest, getNFTTransferFromDigest } from './shared/utilities'

import ER721 from '../artifacts/contracts/StartFiRoyaltyNFT.sol/StartFiRoyaltyNFT.json'
const calcFees=(price:number,share:number,base:number):number=>{

  // round decimal to the nearst value
 return price*(share/(base * 100));

}
chai.use(solidity)
let baseUri = 'http://ipfs.io'
let tokenUri = 'http://ipfs.io'
let chainId:BigNumber;
const name = 'StartFiToken'
const symbol = 'STFI'
const share = 25
const separator = 10 // 2.5
const itemPrice=100;
const muliplyer=10**18;
describe('StartFiToken', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
let walletNftBalance=0
  let token: Contract
  before(async () => {
    token = await deployContract(wallet, ER721, [name, symbol, baseUri])
  })

  it('name, symbol,  DOMAIN_SEPARATOR, PERMIT_TYPEHASH', async () => {
    const _name = await token.name()    
    expect(_name).to.eq(name)
    expect(await token.symbol()).to.eq(symbol)
     chainId = await token.getChainId()
   expect(await token.DOMAIN_SEPARATOR()).to.eq(
      keccak256(
        defaultAbiCoder.encode(
          ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
          [
            keccak256(
              toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
            ),
            keccak256(toUtf8Bytes(name)),
            keccak256(toUtf8Bytes('1')),
            chainId,
            token.address
          ]
        )
      )
    )
    expect(await token.PERMIT_TYPEHASH()).to.eq(
      keccak256(toUtf8Bytes('Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)'))
    )
  })


  it("Should mint with royalty Original issuer share is saved", async () => {
    await expect(await token.mintWithRoyalty(
      wallet.address,
      tokenUri,
      share,separator
    ))
      .to.emit(token, 'Transfer') 
      const info:{ issuer:string, royaltyAmount:BigNumber} = await token.royaltyInfo(
        walletNftBalance,
        itemPrice
     );
     walletNftBalance++;
  const royaltyAmount=Math.round(calcFees(itemPrice,share,separator));
      await expect(info.issuer)
        .to.eq( wallet.address);
        // we have to convert it to string because the expected number is big ' 18 decimals' and js couldn't handle
      await expect(info.royaltyAmount.toString())
        .to.eq(royaltyAmount.toString() );
      
    });

    it("Should mint without royalty", async () => {
  
  
  
      expect(await token.balanceOf(
       wallet.address
     ))
       .to.eq(walletNftBalance);
     await expect(token.mint(
       wallet.address,
       tokenUri
     ))
       .to.emit(token, 'Transfer')  
       walletNftBalance++;
       expect(await token.balanceOf(
         wallet.address
       ))
         .to.eq(walletNftBalance);
     });
  
  it('Contract must support Royalty', async () => {
     expect(await token.supportsRoyalty())
    .to.eq('0x2a55205a' );
        })
  it('Contract must support Premit', async () => {
     expect(await token.supportsPremit())
    .to.eq('0xd505accf' );
        })
        it('permit', async () => {

          const nonce = await token.nonces(wallet.address)  
          const deadline = MaxUint256
          const digest = await getApprovalNftDigest(
            token,
            { owner: wallet.address, spender: other.address, tokenId: 0 },
            nonce,
            deadline,
            chainId,
          )
      
          const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))
      
          await expect(token.permit(wallet.address, other.address, 0, deadline, v, hexlify(r), hexlify(s)))
            .to.emit(token, 'Approval')
            .withArgs(wallet.address, other.address, 0)
          expect(await token.getApproved(0)).to.eq( other.address)
          expect(await token.nonces(wallet.address)).to.eq(BigNumber.from(nonce+1))
        })
  it('transferFrom', async () => {
    await expect(token.transferFrom(wallet.address,other.address, 1))
      .to.emit(token, 'Transfer')
      .withArgs(wallet.address, other.address, 1)
    expect(await token.balanceOf(wallet.address)).to.eq(walletNftBalance-1)
    expect(await token.balanceOf(other.address)).to.eq(1)
  })
  it('transferFrom::fail', async () => {
    await expect(token.transferFrom(wallet.address,other.address, 1))
    .to.be.reverted
  })
 
  it('transferWithPermit', async () => {
    const nonce = await token.nonces(other.address)  
    const deadline = MaxUint256
    const digest = await getNFTTransferFromDigest(
      token,
      { owner: other.address, spender: wallet.address, tokenId: 1 },
      nonce,
      deadline,
      chainId,
    )

    const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(other.privateKey.slice(2), 'hex'))

    await expect(token.transferWithPermit(other.address,wallet.address,  1, deadline, v, hexlify(r), hexlify(s)))
      .to.emit(token, 'Transfer')
     
      .withArgs( other.address,wallet.address,1)
      expect(await token.balanceOf(wallet.address)).to.eq(walletNftBalance)
      expect(await token.balanceOf(other.address)).to.eq(0)
    expect(await token.nonces(other.address)).to.eq(BigNumber.from(nonce+1))  })
})
