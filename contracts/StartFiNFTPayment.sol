// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 import "./interface/IERC721RoyaltyMinter.sol";
/**
 * @author Eman Herawy, StartFi Team
 *@title  StartFi NFT Payment contract
 * desc  contract to handle miniting NFT after contract is approved to transfer the fees by STFI
 */
contract StartFiNFTPayment is Ownable {
 /******************************************* decalrations go here ********************************************************* */
     uint256 _fees=5;
     address private _NFTToken;
    address private _paymentToken;

 /******************************************* constructor goes here ********************************************************* */

  constructor(
        address _nftAddress ,
        address _paymentTokesnAddress
    )   {
         
       
        _NFTToken = _nftAddress;
        _paymentToken = _paymentTokesnAddress;
    }

     /******************************************* read state functions go here ********************************************************* */
  
 /**
     * @dev :wrap function to get the total allowed number of tokens that this contract can transfer from the given account 

    * @param owner: owner address
    * @return allowed number of tokens that this contract can transfer from the owner account
     */
  function _getAllowance(address owner) view private returns (uint256 ) {
        return IERC20(_paymentToken).allowance( owner, address(this));
    }

 /**
    * desc:  function to get all the public info about the contract
    * @return NFt token address, utility token address, minting fees
     */
    function info() view external returns (address,address,uint256) {
        return(_NFTToken,_paymentToken,_fees);
    }
  /******************************************* state functions go here ********************************************************* */

 /**
    * @notice  caller should approve the contract to transfer the fees first
    * @dev : tokens are transfered directly to the admin wallet 
    * @param to: NFT issuer
    * @param _tokenURI: serized json object that has the following data ( category, name , desc , tages, ipfs hash)
    * @param share: eg. 25
    * @param base: eg. 10 
    * @return token id 
     */
function MintNFTWithRoyalty(address to, string memory _tokenURI,uint8 share,uint8 base) external returns(uint256){
    require(_getAllowance(_msgSender())>=_fees,"Not enough fees paid");
    IERC20(_paymentToken). transferFrom(_msgSender(),owner(),  _fees);
 return  IERC721RoyaltyMinter(_NFTToken). mintWithRoyalty(to, _tokenURI, share,base);
}
 /**
    * @notice  caller should approve the contract to transfer the fees first
    * @dev : tokens are transfered directly to the admin wallet 
    * @param to: NFT issuer
    * @param _tokenURI: serized json object that has the following data ( category, name , desc , tages, ipfs hash)
    * @return token id 
     */
function MintNFTWithoutRoyalty(address to, string memory _tokenURI) external returns(uint256){
    require(_getAllowance(_msgSender())>=_fees,"Not enough fees paid");
    IERC20(_paymentToken). transferFrom(_msgSender(),owner(),  _fees);
 return  IERC721RoyaltyMinter(_NFTToken). mint(to, _tokenURI);
}
 /**
    * @notice  only called by admin wallet
    * @param newFees : integer number represents the new fees
    */
   function changeFees(uint256 newFees) external onlyOwner   {
         // fees is a value between 1-3 %
         _fees=newFees;
         
     }
      /**
    * @notice  only called by admin wallet
    * @dev for later on upgrade , if we have
    * @param _nftAddress : startfi new NFT contract
    */
   function changeNftContract(address _nftAddress) external onlyOwner   {
     _NFTToken = _nftAddress;
         
     }
        /**
    * @notice  only called by admin wallet
    * @dev for later on upgrade , if we have
    * @param _paymentTokesnAddress : startfi new utility contract
    */
   function changeTokenContract(address _paymentTokesnAddress) external onlyOwner   {
      _paymentToken = _paymentTokesnAddress;
         
     }
}
