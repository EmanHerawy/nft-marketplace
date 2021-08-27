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

chai.use(solidity)
let baseUri = 'http://ipfs.io'
let tokenUri = 'http://ipfs.io'
const name = 'StartFiToken'
const symbol = 'STFI'
const share = 25
const separator = 10 // 2.5
const itemPrice=1000;
describe('StartFiToken', () => {
  const provider = new MockProvider()
  const [wallet, other] = provider.getWallets()
let walletNftBalance=0
  let token: Contract
  beforeEach(async () => {
    token = await deployContract(wallet, ER721, [name, symbol, baseUri])
  })

  it('name, symbol,  DOMAIN_SEPARATOR, PERMIT_TYPEHASH', async () => {
    const _name = await token.name()    
    expect(_name).to.eq(name)
    expect(await token.symbol()).to.eq(symbol)
    const chainId = await token.getChainId()
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

  it("Should mint with royalty Original issuer share is saved", async () => {
    await expect(await token.mintWithRoyalty(
      wallet.address,
      tokenUri,
      share,separator
    ))
      .to.emit(token, 'Transfer') 
      const info:{ issuer:string, _royaltyAmount:BigNumber} = await token.royaltyInfo(
     0,// tokenid
        itemPrice
     );
  console.log(info,'info');
  const royaltyAmount=itemPrice*share/(separator*100);
  console.log(info._royaltyAmount.toNumber(),'royaltyAmount **');
  console.log(royaltyAmount,'royaltyAmount');
  
      await expect(info.issuer)
        .to.eq( wallet.address);
      await expect(info._royaltyAmount)
        .to.eq(royaltyAmount );
      
    });

    
    //   await token.royaltyInfo(startFiPaymentNFT.address, "10000000000000");
    // const mint = await startFiPaymentNFT.MintNFTWithRoyalty(
    //   wallet.address,
    //   "001",
    //   "1",
    //   "10"
    // );
    // expect(mint.from).to.be.equal(wallet.address);
  // });
  // it('Any one can mint', async () => {
  //   await expect(token.mi(other.address, TEST_AMOUNT))
  //     .to.emit(token, 'Approval')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //   expect(await token.allowance(wallet.address, other.address)).to.eq(TEST_AMOUNT)
  // })

  // it('transfer', async () => {
  //   await expect(token.transfer(other.address, TEST_AMOUNT))
  //     .to.emit(token, 'Transfer')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //   expect(await token.balanceOf(wallet.address)).to.eq(TOTAL_SUPPLY.sub(TEST_AMOUNT))
  //   expect(await token.balanceOf(other.address)).to.eq(TEST_AMOUNT)
  // })

  // it('transfer:fail', async () => {
  //   await expect(token.transfer(other.address, TOTAL_SUPPLY.add(1))).to.be.reverted // ds-math-sub-underflow
  //   await expect(token.connect(other).transfer(wallet.address, 1)).to.be.reverted // ds-math-sub-underflow
  // })

  // it('transferFrom', async () => {
  //   await token.approve(other.address, TEST_AMOUNT)
  //   await expect(token.connect(other).transferFrom(wallet.address, other.address, TEST_AMOUNT))
  //     .to.emit(token, 'Transfer')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //   expect(await token.allowance(wallet.address, other.address)).to.eq(0)
  //   expect(await token.balanceOf(wallet.address)).to.eq(TOTAL_SUPPLY.sub(TEST_AMOUNT))
  //   expect(await token.balanceOf(other.address)).to.eq(TEST_AMOUNT)
  // })

  // it('transferFrom:max', async () => {
  //   await token.approve(other.address, MaxUint256)
  //   await expect(token.connect(other).transferFrom(wallet.address, other.address, TEST_AMOUNT))
  //     .to.emit(token, 'Transfer')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //   // expect(await token.allowance(wallet.address, other.address)).to.eq(MaxUint256)
  //   expect(await token.balanceOf(wallet.address)).to.eq(TOTAL_SUPPLY.sub(TEST_AMOUNT))
  //   expect(await token.balanceOf(other.address)).to.eq(TEST_AMOUNT)
  // })

  // it('permit', async () => {
  //   const nonce = await token.nonces(wallet.address)  
  //   const deadline = MaxUint256
  //   const digest = await getApprovalNftDigest(
  //     token,
  //     { owner: wallet.address, spender: other.address, value: TEST_AMOUNT },
  //     nonce,
  //     deadline,
  //     chainId,
  //   )

  //   const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))

  //   await expect(token.permit(wallet.address, other.address, TEST_AMOUNT, deadline, v, hexlify(r), hexlify(s)))
  //     .to.emit(token, 'Approval')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //   expect(await token.allowance(wallet.address, other.address)).to.eq(TEST_AMOUNT)
  //   expect(await token.nonces(wallet.address)).to.eq(BigNumber.from(nonce+1))
  // })
  // it('transferWithPermit', async () => {
  //   const nonce = await token.nonces(wallet.address)  
  //   const deadline = MaxUint256
  //   const digest = await getNFTTransferFromDigest(
  //     token,
  //     { owner: wallet.address, spender: other.address, value: TEST_AMOUNT },
  //     nonce,
  //     deadline,
  //     chainId,
  //   )

  //   const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(wallet.privateKey.slice(2), 'hex'))

  //   await expect(token.transferWithPermit(wallet.address, other.address, TEST_AMOUNT, deadline, v, hexlify(r), hexlify(s)))
  //     .to.emit(token, 'Transfer')
  //     .withArgs(wallet.address, other.address, TEST_AMOUNT)
  //     expect(await token.balanceOf(wallet.address)).to.eq(TOTAL_SUPPLY.sub(TEST_AMOUNT))
  //     expect(await token.balanceOf(other.address)).to.eq(TEST_AMOUNT)
  //     expect(await token.nonces(wallet.address)).to.eq(BigNumber.from(nonce+1))
  // })
})
