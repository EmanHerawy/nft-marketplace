// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC721RoyaltyMinter {
 function mint(address to, string memory _tokenURI) external  returns(uint256);
 function mintWithRoyalty(address to, string memory _tokenURI,uint8 share,uint8 base) external  returns(uint256);
}