// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import './interface/IERC721Royalty.sol';
import './library/StartFiFinanceLib.sol';

/**
 
 *@title  ERC721 Royalty
 * [ desc ] : erc721 with reoylaty support interface
 */
contract ERC721Royalty is IERC721Royalty {
    mapping(uint256 => address) private tokenIdToIssuer;
    mapping(uint256 => mapping(address => Base)) private _issuerPercentage;
    event MintWithRoyalty(uint256 tokenId, uint256 share, uint256 base, address issuer);
    // 3.5 is 35 share and 10 separator
    struct Base {
        uint8 share;
        uint8 shareSeparator;
    }

    /**
     *
     * @dev  set roylaity info
     * @param _tokenId: serized json object that has the following data ( category, name , desc , tages, ipfs hash)
     * @param issuer: NFt original issuer
     * @param share: eg. 25
     * @param separator: eg. 10
     *
     */
    function _supportRoyalty(
        uint256 _tokenId,
        address issuer,
        uint8 share,
        uint8 separator
    ) internal {
        require(share > 0 && separator > 0, 'separator and Share values must be more than zero');
        tokenIdToIssuer[_tokenId] = issuer;
        _issuerPercentage[_tokenId][issuer] = Base(share, separator);
        emit MintWithRoyalty(_tokenId, share, separator, issuer);
    }

    function getTokenIssuer(uint256 tokenId) external view returns (address issuer) {
        return tokenIdToIssuer[tokenId];
    }

    /**
     
    * @dev  the formula is as follow : if issuer share is 2.5 then the share is 25 and the separator is 10 
    * so inorder to calc the amount of royalty share for a token , formula should be totoal (price * share)/(separator*100)
    * @param _tokenId : token id
    * @param _value : token price on marketplace 
    * @return issuer : original issuer of the given token and his/her share of this this token
     */
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        override
        returns (address issuer, uint256 royaltyAmount)
    {
        issuer = tokenIdToIssuer[_tokenId];
        if (issuer != address(0)) {
            Base memory _base = _issuerPercentage[_tokenId][issuer];
            royaltyAmount = StartFiFinanceLib._calcFees(_value, uint256(_base.share), uint256(_base.shareSeparator));
        }
    }

    // 0x2a55205a
    // 0x2a55205a
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsRoyalty() public pure returns (bytes4 interfaceId) {
        return type(IERC721Royalty).interfaceId;
    }
}
