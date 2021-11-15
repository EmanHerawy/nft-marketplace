// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStartFiMarketplace {
    function getUserReserved(address user) external view returns (uint256);
}
