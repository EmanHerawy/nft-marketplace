// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import '@openzeppelin/contracts/utils/Counters.sol';

import './ERC721MinterPauser.sol';

import './ERC721Royalty.sol';
import './StartfiSignatureLib.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  Startfi Royalty NFT
 * [ desc ] : NFT contract with Royalty option
 *
 */
contract StartfiRoyaltyNFT is ERC721Royalty, ERC721MinterPauser {
    using Counters for Counters.Counter;
    bytes32 public DOMAIN_SEPARATOR;

    Counters.Counter private _tokenIdTracker;
    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping(address => uint256) public nonces;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256('Transfer(address owner,address to,uint256 tokenId,uint256 nonce,uint256 deadline)');

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721MinterPauser(name, symbol, baseTokenURI) {
        uint256 chainId;
        assembly {
            chainId := chainId
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Sets `tokenId` as allowance of `spender` account over `owner` account's StartfiRoyaltyNFT token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` or 'approved for all' account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner`  or 'approved for all' account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// StartfiRoyaltyNFT token implementation adapted from https://github.com/anyswap/chaindata/blob/main/AnyswapV5ERC20.sol. with some modification
    function permit(
        address target,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, 'StartFi: Expired permit');

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_TYPEHASH, target, spender, tokenId, nonces[target]++, deadline)
        );

        require(
            StartfiSignatureLib.verifyEIP712(target, hashStruct, v, r, s, DOMAIN_SEPARATOR) ||
                StartfiSignatureLib.verifyPersonalSign(target, hashStruct, v, r, s, DOMAIN_SEPARATOR)
        );
        address owner = ERC721.ownerOf(tokenId);
        require(spender != owner, 'ERC721: approval to current owner');

        require(
            target == owner || isApprovedForAll(owner, target),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(spender, tokenId);
    }

    /// @dev Sets `tokenId` as allowance of `spender` account over `owner` account's StartfiRoyaltyNFT token, given `owner` account's signed approval.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` or 'approved for all' account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner`  or 'approved for all' account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// StartfiRoyaltyNFT token implementation adapted from https://github.com/anyswap/chaindata/blob/main/AnyswapV5ERC20.sol. with some modification

    function transferWithPermit(
        address target,
        address to,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(block.timestamp <= deadline, 'StartFi: Expired permit');

        bytes32 hashStruct = keccak256(abi.encode(TRANSFER_TYPEHASH, target, to, tokenId, nonces[target]++, deadline));

        require(
            StartfiSignatureLib.verifyEIP712(target, hashStruct, v, r, s, DOMAIN_SEPARATOR) ||
                StartfiSignatureLib.verifyPersonalSign(target, hashStruct, v, r, s, DOMAIN_SEPARATOR)
        );

        require(to != address(0) || to != address(this));

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
        require(hasRole(MINTER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have minter role to mint');
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
        require(hasRole(MINTER_ROLE, _msgSender()), 'ERC721PresetMinterPauserAutoId: must have minter role to mint');

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721MinterPauser) returns (bool) {
        return interfaceId == supportsRoyalty() || super.supportsInterface(interfaceId);
    }
}
