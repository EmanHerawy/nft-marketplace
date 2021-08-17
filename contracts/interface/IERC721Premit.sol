// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721Premit {
    function permit(
        address target,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external  returns (bool);
}
