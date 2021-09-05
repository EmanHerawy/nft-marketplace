// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
import './interface/IERC721Premit.sol';
import './library/StartFiSignatureLib.sol';

/**
 * @author Eman Herawy, StartFi Team
 *@title  ERC721 Royalty
 * [ desc ] : erc721 with reoylaty support interface
 */
abstract contract ERC721Premit is IERC721Premit {
    bytes32 public DOMAIN_SEPARATOR;

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping(address => uint256) public nonces;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256('Transfer(address owner,address to,uint256 tokenId,uint256 nonce,uint256 deadline)');

    constructor(string memory name) {
        uint256 chainId;
        assembly {
            chainId := chainid()
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

    function getChainId() external view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
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
    function _permitCheck(
        address target,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(block.timestamp <= deadline, 'StartFi: Expired permit');

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_TYPEHASH, target, spender, tokenId, nonces[target]++, deadline)
        );

        require(
            StartFiSignatureLib.verifyEIP712(target, hashStruct, v, r, s, DOMAIN_SEPARATOR) ||
                StartFiSignatureLib.verifyPersonalSign(target, hashStruct, v, r, s, DOMAIN_SEPARATOR)
        );
        require(spender != address(0) || spender != address(this));
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

    function _transferWithPermitCheck(
        address target,
        address to,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        require(block.timestamp <= deadline, 'StartFi: Expired permit');

        bytes32 hashStruct = keccak256(abi.encode(TRANSFER_TYPEHASH, target, to, tokenId, nonces[target]++, deadline));

        require(
            StartFiSignatureLib.verifyEIP712(target, hashStruct, v, r, s, DOMAIN_SEPARATOR) ||
                StartFiSignatureLib.verifyPersonalSign(target, hashStruct, v, r, s, DOMAIN_SEPARATOR)
        );

        require(to != address(0) || to != address(this));

        return true;
    }

    // 0xd505accf
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsPremit() public pure returns (bytes4 interfaceId) {
        return type(IERC721Premit).interfaceId;
    }
}
