// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IERC721Royalty.sol";

/**
 * @author Eman Herawy StartFi Team
 *@title base cmarket place contract
 * Note: This marketplace contract is collection based. It serves one ERC721 contract only
 * Payment tokens usually is the chain native coin's wrapped token, e.g. WETH, WBNB
 */
contract MarketPlaceBase is  ERC721Holder {
    /******************************************* decalrations go here ********************************************************* */

    string private _marketPlaceName;
    bytes4   RORALTY_INTERFACE= 0x2a55205a;
 /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _name 
    )  {
        _marketPlaceName = _name;
       
         
    }

 /******************************************* read state functions go here ********************************************************* */
 function _supportRoyalty(address contractAddress) view internal  returns (bool) {
       try IERC721(contractAddress).supportsInterface(RORALTY_INTERFACE) returns (bool isRoyaltySupported) {
            return isRoyaltySupported;
        } catch {
            return false;
        }
 }
 function _getRoyaltyInfo(address contractAddress, uint256 _tokenId, uint256 _value) view internal  returns (address issuer, uint256 _royaltyAmount) {
       (issuer, _royaltyAmount) =IERC721Royalty(contractAddress).royaltyInfo( _tokenId,   _value) ;
 }
    /**
     * @return market place name
     */
    function marketPlaceName() external view returns (string memory) {
        return _marketPlaceName;
    }
    /**
     * @dev check if the account is the owner of this erc721 token
     */
    function tokenOwner(address contractAddress, uint256 tokenId) internal view returns (address) {
       return IERC721(contractAddress).ownerOf(tokenId) ;
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function _isTokenApproved(address contractAddress, uint256 tokenId) internal view returns (bool) {
        try IERC721(contractAddress).getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
      
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function _isAllTokenApproved(address contractAddress,address owner) internal view returns (bool) {
        return IERC721(contractAddress).isApprovedForAll(owner, address(this));
    }  

      /******************************************* state functions go here ********************************************************* */

      /// @param _name  the new name to be stored 
     function _changeMarketPlaceName(string memory _name)internal {
      _marketPlaceName=_name;  
     }
  
    
    function _safeNFTTransfer(address contractAddress, uint256 tokenId, address from, address to) internal returns (bool) {
       IERC721(contractAddress). safeTransferFrom( from,  to,  tokenId);
       return true;
    }



}  

   
