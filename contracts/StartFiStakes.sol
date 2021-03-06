// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.4;

import './interface/IStartFiStakes.sol';
import './interface/IStartFiMarketPlace.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 
 *@title  StartFi Stakes
 * [ desc ] : contract to hold users stakes
 *@notice : the logic behind this contract is not implemented yet, this is just a basic design for the sake of testing the marketplace cycle
 */

contract StartFiStakes is Ownable, IStartFiStakes {
    /******************************************* decalrations go here ********************************************************* */
    mapping(address => uint256) stakerReserved;
    address marketplace;
    address stfiToken;
    /******************************************* modifiers go here ********************************************************* */
    modifier onlyMarketplace() {
        require(_msgSender() == marketplace, 'Caller is not the marketplace');
        _;
    }

    /******************************************* constructor goes here ********************************************************* */

    constructor(address _stfiToken, address _owner) {
        stfiToken = _stfiToken;
        transferOwnership(_owner);
    }

    /******************************************* read state functions go here ********************************************************* */

    // deposit
    function deposit(address user, uint256 amount) external {
        require(_getAllowance(_msgSender()) >= amount, 'Invalid amount');
        _safeTokenTransferFrom(_msgSender(), address(this), amount);
        stakerReserved[user] = stakerReserved[user] + amount;
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function _safeTokenTransfer(address to, uint256 amount) private returns (bool) {
        return IERC20(stfiToken).transfer(to, amount);
    }

    function _safeTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        return IERC20(stfiToken).transferFrom(from, to, amount);
    }

    // withdraw
    function withdraw(uint256 amount) external {
        // TODO:check marketplace user reserves
        uint256 reserves = IStartFiMarketPlace(marketplace).getUserReserved(_msgSender());
        uint256 allowance = stakerReserved[_msgSender()] - reserves;
        require(allowance >= amount, 'Invalid amount');
        _safeTokenTransfer(_msgSender(), amount);
        stakerReserved[_msgSender()] = stakerReserved[_msgSender()] - amount;
    }

    // punish
    function deduct(
        address finePayer,
        address to,
        uint256 amount /*onlyMarketplace*/
    ) external override returns (bool) {
        require(stakerReserved[finePayer] >= amount, 'Invalid amount');
        stakerReserved[finePayer] = stakerReserved[finePayer] - amount;
        stakerReserved[to] = stakerReserved[to] + amount;
        return true;
    }

    //getpoolinfo
    function getReserves(address owner) external view override returns (uint256) {
        return stakerReserved[owner];
    }

    function _getAllowance(address owner) private view returns (uint256) {
        return IERC20(stfiToken).allowance(owner, address(this));
    }
}
