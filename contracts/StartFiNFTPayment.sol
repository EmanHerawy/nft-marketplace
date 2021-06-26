// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 import "./interface/IERC721RoyaltyMinter.sol";

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
  function _getAllowance(address owner) view private returns (uint256 ) {
        return IERC20(_paymentToken).allowance( owner, address(this));
    }
    function info() view external returns (address,address,uint256) {
        return(_NFTToken,_paymentToken,_fees);
    }
  /******************************************* state functions go here ********************************************************* */
function MintNFTWithRoyalty(address to, string memory _tokenURI,uint8 share,uint8 base) external returns(uint256){
    require(_getAllowance(_msgSender())>=_fees,"Not enough fees paid");
    IERC20(_paymentToken). transferFrom(_msgSender(),owner(),  _fees);
 return  IERC721RoyaltyMinter(_NFTToken). mintWithRoyalty(to, _tokenURI, share,base);
}
function MintNFTWithoutRoyalty(address to, string memory _tokenURI) external returns(uint256){
    require(_getAllowance(_msgSender())>=_fees,"Not enough fees paid");
    IERC20(_paymentToken). transferFrom(_msgSender(),owner(),  _fees);
 return  IERC721RoyaltyMinter(_NFTToken). mint(to, _tokenURI);
}
   function changeFees(uint256 newFees) external onlyOwner   {
         // fees is a value between 1-3 %
         _fees=newFees;
         
     }
   function changeNftContract(address _nftAddress) external onlyOwner   {
     _NFTToken = _nftAddress;
         
     }
   function changeTokenContract(address _paymentTokesnAddress) external onlyOwner   {
      _paymentToken = _paymentTokesnAddress;
         
     }
}
