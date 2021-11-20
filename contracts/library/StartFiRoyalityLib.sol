// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import '../interface/IERC721Royalty.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

library StartFiRoyalityLib {
    bytes4 constant RORALTY_INTERFACE = 0x2a55205a;

    /**
     *@notice  only if this contract has royaltyInfo function
     *@dev  call the royaltyInfo function in nft contract
     *@param _token NFT contract address
     *@param _tokenId token id
     *@param _value  token price
     *@return issuer original issuer address
     *@return royaltyAmount  the issuer total amount of tokens that he should recieve based on his share
     */
    function _getRoyaltyInfo(
        address _token,
        uint256 _tokenId,
        uint256 _value
    ) internal view returns (address issuer, uint256 royaltyAmount) {
        (issuer, royaltyAmount) = IERC721Royalty(_token).royaltyInfo(_tokenId, _value);
    }

    /**
     *
     * @dev  interal function to check if any gevin contract has supportsInterface See {IERC165-supportsInterface}.
     * @param _token NFT contract address
     * @return true if this NFT contract support royalty, false if not
     */
    function _supportRoyalty(address _token) internal view returns (bool) {
        try IERC165(_token).supportsInterface(RORALTY_INTERFACE) returns (bool isRoyaltySupported) {
            return isRoyaltySupported;
        } catch {
            return false;
        }
    }
}
