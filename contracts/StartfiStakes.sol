// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.0;

import "./interface/IStartFiStakes.sol";
import "./interface/IStartFiMarketplace.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StartfiStakes is Ownable, IStartFiStakes {
    /******************************************* decalrations go here ********************************************************* */
    using SafeMath for uint256;
    mapping (address=>uint256) stakerReserved;
    address marketplace;
    address stfiToken;
 /******************************************* modifiers go here ********************************************************* */
 modifier onlyMarketplace() {
     require(_msgSender()==marketplace,"Caller is not the marketplace");
     _;
 }
 
 /******************************************* constructor goes here ********************************************************* */

    constructor(
        
          address _stfiToken
    )  {
       stfiToken=_stfiToken;
    }



     /******************************************* read state functions go here ********************************************************* */

// deposit 
function deposit(address user,uint256 amount) external  {
    require(_getAllowance(_msgSender())>=amount,"Invalid amount");
    _safeTokenTransferFrom(_msgSender(),address(this),amount);
     stakerReserved[user]= stakerReserved[user].add(amount);

}
function setMarketplace(address _marketplace) external onlyOwner  {
    marketplace=_marketplace;
}
 function _safeTokenTransfer(address to, uint256 amount) private returns (bool) {
        return IERC20(stfiToken). transfer( to,  amount);
    }
  function _safeTokenTransferFrom(address from,address to, uint256 amount) private returns (bool) {
        return IERC20(stfiToken). transferFrom(from, to,  amount);
    }
// withdraw
function withdraw(uint256 amount)  external {
    // TODO:check marketplace user reserves 
    uint256 reserves = IStartFiMarketplace(marketplace).getUserReserved(_msgSender());
    uint256 allowance = stakerReserved[_msgSender()].sub(reserves);
    require( allowance<=amount,"Invalid amount");
    _safeTokenTransfer(_msgSender(),amount);
     stakerReserved[_msgSender()]= stakerReserved[_msgSender()].sub(amount);

}
// punish
function deduct(address finePayer, address to, uint256 amount) external override onlyMarketplace returns (bool) {
           require( stakerReserved[finePayer]<=amount,"Invalid amount");
         stakerReserved[finePayer]= stakerReserved[finePayer].sub(amount);
              stakerReserved[to]= stakerReserved[to].add(amount);
              return true;


}
//getpoolinfo 
 function getReserves(address owner) external override view returns ( uint256){
        return stakerReserved[owner];
 }
     function _getAllowance(address owner) view private returns (uint256 ) {
        return IERC20(stfiToken).allowance( owner, address(this));
    }
}
