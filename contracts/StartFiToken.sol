// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;
pragma experimental SMTChecker;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

/**
 * @author Eman Herawy, StartFi Team
 *@title  Start FiToken
 * desc A Startfi Utiltiy token
 */
contract StartFiToken is ERC20PresetFixedSupply{
    constructor(string memory name,
        string memory symbol,
        /*uint256 initialSupply,*/
        address owner) ERC20PresetFixedSupply(name,symbol,100000000 * 1 ether,owner)  {

         
    }

}
