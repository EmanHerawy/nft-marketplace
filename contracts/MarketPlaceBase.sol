// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import './StartFiMarketPlaceAdmin.sol';

/**
 
 *@title  MarketPlace Base
 * [ desc ] : contract to handle the main functions for any marketplace
 */
contract MarketPlaceBase is ERC721Holder, StartFiMarketPlaceAdmin {
    /******************************************* decalrations go here ********************************************************* */

    string private _marketPlaceName;

    /******************************************* constructor goes here ********************************************************* */

    function _MarketplaceBase_init_unchained(string memory _name) internal {
        _marketPlaceName = _name;
    }

    /******************************************* read state functions go here ********************************************************* */

    /**
     * @return market place name
     */
    function marketPlaceName() external view returns (string memory) {
        return _marketPlaceName;
    }

    /******************************************* state functions go here ********************************************************* */

    /**
     * @dev only called by `owner` to change the name and `whenPaused`
     *@param _name marketplace new name
     *
     */
    function changeMarketPlaceName(string memory _name) external onlyOwner whenPaused {
        _marketPlaceName = _name;
        emit ChangeMarketPlaceName(_name);
    }
}
