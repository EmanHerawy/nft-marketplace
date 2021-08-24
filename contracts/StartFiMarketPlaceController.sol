// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.7;
pragma abicoder v2;
import './interface/IStartFiReputation.sol';
import './interface/IERC20.sol';
import './interface/IERC721Premit.sol';
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

    mapping(address => bytes32[]) userListing;

    /******************************************* constructor goes here ********************************************************* */

    constructor(
        string memory _name,
        address _paymentContract,
        address _reputationContract
    ) MarketPlaceBase(_name) StartFiMarketPlaceFinance(_paymentContract, _reputationContract) {
        _paymentToken = _paymentContract;
        reputationContract = _reputationContract;
    }

    /******************************************* modifiers go here ********************************************************* */
    /**
     *@param user  : participant address
     * @return the value of user reserves
     */
    function getUserReserved(address user) external view returns (uint256) {
        return userReserves[user];
    }

    function _getAllowance(address owner) internal view returns (uint256) {
        return IERC20(_paymentToken).allowance(owner, address(this));
    }

    /******************************************* read state functions go here ********************************************************* */

    function _premitNFT(
        address _NFTContract,
        address target,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        if (_supportPremit(_NFTContract)) {
            return IERC721Premit(_paymentToken).permit(target, address(this), tokenId, deadline, v, r, s);
        } else {
            return false;
        }
    }

    function _safeTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(_paymentToken).transferFrom(from, to, amount);
    }

    function _permit(
        address target,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool) {
        IERC20(_paymentToken).permit(target, address(this), price, deadline, v, r, s);
        return true;
    }
}
