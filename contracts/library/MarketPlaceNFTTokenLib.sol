// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '../interface/IERC721.sol';

library MarketPlaceNFTTokenLib {
    bytes4 constant PREMIT_INTERFACE = 0x2a55205a;

    // erc721
    /**
     *
     * @dev  interal function to check if any gevin contract has supportsInterface See {IERC165-supportsInterface}.
     * @param _token NFT contract address
     * @return true if this NFT contract support royalty, false if not
     */
    function _supportPermit(address _token) internal view returns (bool) {
        try IERC721(_token).supportsInterface(PREMIT_INTERFACE) returns (bool isPermitSupported) {
            return isPermitSupported;
        } catch {
            return false;
        }
    }

    /**

     * @dev check if this contract has approved to transfer this erc721 token
     *@param _token NFT contract address
     *@param tokenId token id
     * @return true if this contract is apporved , false if not
     */
    function _isTokenApproved(address _token, uint256 tokenId) internal view returns (bool) {
        try IERC721(_token).getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    // /**
    //  *@dev See {IERC721-isApprovedForAll}.
    //  *@dev check if this contract has approved to all of this owner's erc721 tokens
    //  *@param _token NFT contract address
    //  *@param owner token owner
    //  *@return true if this contract is apporved , false if not
    //  */
    function _isAllTokenApproved(address _token, address owner) internal view returns (bool) {
        return IERC721(_token).isApprovedForAll(owner, address(this));
    }

    /**
     * @dev  Safely transfers `tokenId` token from `from` to `to`. by calling the base erc721 contract
     *@param _token NFT contract address
     *@param tokenId token id
     *@param from sender
     *@param to recipient
     * @return true if it's done
     * See {safeTransferFrom}
     */
    function _safeNFTTransfer(
        address _token,
        uint256 tokenId,
        address from,
        address to
    ) internal returns (bool) {
        IERC721(_token).safeTransferFrom(from, to, tokenId);
        return true;
    }

    /**
    * @dev called by the contract to get who much token this contract is allowed to spend from the `owner` account
     * @param _token nft contract address
     * @param tokenId token id
     * @param target token owner
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return true when done, false if not
     */
    function _permitNFT(
        address _token,
        address target,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        if (_supportPermit(_token)) {
            return IERC721(_token).permit(target, address(this), tokenId, deadline, v, r, s);
        } else {
            return false;
        }
    }
}
