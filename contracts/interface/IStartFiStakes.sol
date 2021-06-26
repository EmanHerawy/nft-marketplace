// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IStartFiStakes {
 function getReserves(address owner) external view returns ( uint256) ;
 function deduct(address finePayer, address to, uint256 amount) external returns (bool);  
}