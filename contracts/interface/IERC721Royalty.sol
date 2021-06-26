// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC721Royalty {
 function royaltyInfo(uint256 _tokenId, uint256 _value) external view returns (address issuer, uint256 _royaltyAmount) ;  
}