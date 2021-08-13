// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IERC721Royalty.sol";

/**
 * @author Eman Herawy, StartFi Team
 *@title  MarketPlace Base
 * [ desc ] : contract to handle the main functions for any marketplace
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
     /**
    * 
    * @dev  interal function to check if any gevin contract has supportsInterface See {IERC165-supportsInterface}.
    * @param _NFTContract NFT contract address
    * @return true if this NFT contract support royalty, false if not
     */
 function _supportRoyalty(address _NFTContract) view internal  returns (bool) {
       try IERC721(_NFTContract).supportsInterface(RORALTY_INTERFACE) returns (bool isRoyaltySupported) {
            return isRoyaltySupported;
        } catch {
            return false;
        }
 }
 /**
    *@notice  only if this contract has royaltyInfo function 
    *@dev  call the royaltyInfo function in nft contract
    *@param _NFTContract NFT contract address
    *@param _tokenId token id
    *@param _value  token price
    *@return issuer original issuer address
    *@return _royaltyAmount  the issuer total amount of tokens that he should recieve based on his share
     */
 function _getRoyaltyInfo(address _NFTContract, uint256 _tokenId, uint256 _value) view internal  returns (address issuer, uint256 _royaltyAmount) {
       (issuer, _royaltyAmount) =IERC721Royalty(_NFTContract).royaltyInfo( _tokenId,   _value) ;
 }

    /**
       * @return market place name
      */
    function marketPlaceName() external view returns (string memory) {
        return _marketPlaceName;
    }
    
    /**
    *@param _NFTContract NFT contract address
    *@param tokenId token id
    * @return the owner of the gevin token id and address
     */
    function tokenOwner(address _NFTContract, uint256 tokenId) internal view returns (address) {
       return IERC721(_NFTContract).ownerOf(tokenId) ;
    }

    /**

     * @dev check if this contract has approved to transfer this erc721 token
     *@param _NFTContract NFT contract address
     *@param tokenId token id
     * @return true if this contract is apporved , false if not
     */
    function _isTokenApproved(address _NFTContract, uint256 tokenId) internal view returns (bool) {
        try IERC721(_NFTContract).getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
      
    }

    /**
     *@dev See {IERC721-isApprovedForAll}.
     *@dev check if this contract has approved to all of this owner's erc721 tokens
     *@param _NFTContract NFT contract address
     *@param owner token owner
     *@return true if this contract is apporved , false if not
     */
    function _isAllTokenApproved(address _NFTContract,address owner) internal view returns (bool) {
        return IERC721(_NFTContract).isApprovedForAll(owner, address(this));
    }  

      /******************************************* state functions go here ********************************************************* */

    
    /**
        * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
        *
        * See {setApprovalForAll}
     */
     function _changeMarketPlaceName(string memory _name)internal {
      _marketPlaceName=_name;  
     }
  
      /**
        * @dev  Safely transfers `tokenId` token from `from` to `to`. by calling the base erc721 contract
        *@param _NFTContract NFT contract address
        *@param tokenId token id
        *@param from sender 
        *@param to recipient
        * @return true if it's done
        * See {safeTransferFrom}
     */
    function _safeNFTTransfer(address _NFTContract, uint256 tokenId, address from, address to) internal returns (bool) {
       IERC721(_NFTContract). safeTransferFrom( from,  to,  tokenId);
       return true;
    }



}  

   
