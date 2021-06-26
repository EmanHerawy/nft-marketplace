// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IStartFiMarketplace {
 function getUserReserved(address user) external  view returns (uint256) ;  
}