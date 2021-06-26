// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IERC721Royalty.sol";

contract ERC721Royalty is IERC721Royalty {
    using SafeMath for uint256;
    mapping (uint256 => address) internal _issuer;
    mapping (uint256 => mapping (address=>Base) ) internal _issuerPercentage;
 
 // 3.5 is 35 share and 10 base 
   struct Base{
        uint8 share;
        uint8 sharebase;
    }
  
   
    function _supportRoyalty( uint256 _tokenId,address issuer, uint8 share,uint8 base) internal {
        _issuer[_tokenId]=issuer;
        _issuerPercentage[_tokenId][issuer]= Base(share,base);
    }
function royaltyInfo(uint256 _tokenId, uint256 _value) external view  override returns (address issuer, uint256 _royaltyAmount){
     issuer = _issuer[_tokenId];
    if(issuer!=address(0)){
     Base memory _base=_issuerPercentage[_tokenId][issuer];
        _royaltyAmount = _value.mul(uint256 (_base.share)).div(100).div(uint256(_base.sharebase));
    }
}
// 0x2a55205a
    function supportsRoyalty() public pure  returns (bytes4 interfaceId) {
        return  type(IERC721Royalty).interfaceId;
    }

}
