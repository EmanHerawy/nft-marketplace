// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
pragma abicoder v2;
import './interface/IStartFiReputation.sol';
import './interface/IERC20.sol';
import './interface/IERC721Permit.sol';
import './interface/IStartFiStakes.sol';
import './MarketPlaceBase.sol';
import './MarketPlaceListing.sol';
import './MarketPlaceBid.sol';
import './StartFiMarketPlaceFinance.sol';
import './StartFiMarketPlaceSpecialOffer.sol';
import './StartFiMarketPlaceCap.sol';

/**
 * @author Eman Herawy, StartFi Team
 *desc   contract to handle all financial work for the marketplace
 * @title StartFi Marketplace Finance
 */
contract StartFiMarketPlaceController is
    MarketPlaceBase,
    StartFiMarketPlaceFinance,
    StartFiMarketPlaceCap,
    StartFiMarketPlaceSpecialOffer,
    MarketPlaceListing,
    MarketPlaceBid
{
    /******************************************* decalrations go here ********************************************************* */

    mapping(address => bytes32[]) internal userBids;

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _name,
        address _paymentContract,
        address _reputationContract
    ) MarketPlaceBase(_name) StartFiMarketPlaceFinance(_paymentContract, _reputationContract) {}

    /******************************************* modifiers go here ********************************************************* */
    /**
     * @dev called by the dapp to get the user stakes on hold
     *@param user  : participant address
     * @return the value of user reserves
     */
    function getUserReserved(address user) external view returns (uint256) {
        return userReserves[user];
    }

    /**
     * @dev called by the contract to get who much token this contract is allowed to spend from the `owner` account
     *@param owner  : token owner address
     * @return the value of allowence
     */
    function _getAllowance(address owner) internal view returns (uint256) {
        return IERC20(_paymentToken).allowance(owner, address(this));
    }

    /******************************************* read state functions go here ********************************************************* */
    /**
    * @dev called by the contract to get who much token this contract is allowed to spend from the `owner` account
     * @param _NFTContract nft contract address
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
        address _NFTContract,
        address target,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        if (_supportPermit(_NFTContract)) {
            return IERC721Permit(_NFTContract).permit(target, address(this), tokenId, deadline, v, r, s);
        } else {
            return false;
        }
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     */
    function _safeTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(_paymentToken).transferFrom(from, to, amount);
    }

    /**
    /// @dev Sets `value` as allowance of `spender` account over `owner` account's STFI token, given `owner` account's signed approval.
    /// Emits {Approval} event.
     * @param amount amount to transfer
     * @param target token owner
     * @param deadline:  must be timestamp in future .
     * @param v needed to recover the public key
     * @param r : normal output of an ECDSA signature
     * @param s: normal output of an ECDSA signature
     * `v`, `r` and `s` must be valid `secp256k1` signature from `owner`  or 'approved for all' account over EIP712-formatted function arguments.
  
     * @return true when done, false if not
     */
    function _permit(
        address target,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        IERC20(_paymentToken).permit(target, address(this), amount, deadline, v, r, s);
        return true;
    }
}
