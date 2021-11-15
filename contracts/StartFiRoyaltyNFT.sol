// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import './ERC721Permit.sol';
import './ERC721Royalty.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  StartFi Royalty NFT
 * [ desc ] : NFT contract with Royalty option
 *
 */
contract StartFiRoyaltyNFT is ReentrancyGuard, ERC721Royalty, ERC721Permit, ERC721Enumerable,ERC721URIStorage {
    using Counters for Counters.Counter;
 
     Counters.Counter private _tokenIdTracker;

 
    constructor(
        string memory name,
        string memory symbol
     ) ERC721(name, symbol) ERC721Permit(name) {
     }


   function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
     return super.tokenURI(tokenId);
    }
    /// @dev Sets `tokenId` as allowance of `spender` account over `owner` account's StartFiRoyaltyNFT token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` or 'approved for all' account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner`  or 'approved for all' account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// StartFiRoyaltyNFT token implementation adapted from https://github.com/anyswap/chaindata/blob/main/AnyswapV5ERC20.sol. with some modification
    function permit(
        address target,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (bool) {
        require(_permitCheck(target, spender, tokenId, deadline, v, r, s), 'StartFi NFT: Invalid signature');

        address owner = ERC721.ownerOf(tokenId);
        require(spender != owner, 'ERC721: approval to current owner');

        require(
            target == owner || isApprovedForAll(owner, target),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(spender, tokenId);

        return true;
    }

    /// @dev Sets `tokenId` as allowance of `spender` account over `owner` account's StartFiRoyaltyNFT token, given `owner` account's signed approval.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` or 'approved for all' account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner`  or 'approved for all' account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// StartFiRoyaltyNFT token implementation adapted from https://github.com/anyswap/chaindata/blob/main/AnyswapV5ERC20.sol. with some modification

    function transferWithPermit(
        address target,
        address to,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(_transferWithPermitCheck(target, to, tokenId, deadline, v, r, s), 'StartFi NFT: Invalid signature');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            target == owner || isApprovedForAll(owner, target),
            'ERC721: approve caller is not owner nor approved for all'
        );
        _safeTransfer(target, to, tokenId, '');
        return true;
    }

    /**
     * @notice  mint new NFT with roylty support, soldidty doesn't support decimal, so if we want to add 2.5 % share we need to pass 25 as share and 10 as base
     * @dev  calller should be in minter role
     * @param to: NFT issuer
     * @param _tokenURI: serized json object that has the following data ( category, name , desc , tages, ipfs hash)
     * @param share: eg. 25
     * @param separator: eg. 10
     * @return token id
     */
    function mintWithRoyalty(
        address to,
        string memory _tokenURI,
        uint8 share,
        uint8 separator
    ) external virtual returns (uint256) {
        // require(hasRole(MINTER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have minter role to mint');
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _supportRoyalty(_tokenIdTracker.current(), to, share, separator);
        _mint(to, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), _tokenURI);
        _tokenIdTracker.increment();
        return _tokenIdTracker.current();
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory _tokenURI) public virtual returns (uint256) {
        // require(hasRole(MINTER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have minter role to mint');

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), _tokenURI);
        _tokenIdTracker.increment();
        return _tokenIdTracker.current();
    }

    // 0x2a55205a
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,ERC721Enumerable) returns (bool) {
        return
            interfaceId == supportsRoyalty() || interfaceId == supportsPermit() || super.supportsInterface(interfaceId);
    }

  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn( tokenId);
    }
    // adding nonReentrant guard , https://www.paradigm.xyz/2021/08/the-dangers-of-surprising-code/
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override nonReentrant {
        super._safeTransfer(from, to, tokenId, _data);
    }
}
