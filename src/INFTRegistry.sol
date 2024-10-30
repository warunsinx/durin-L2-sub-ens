/// @author darianb.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INFTRegistry {
    // ERC721 methods
    function ownerOf(uint256 tokenId) external view returns (address);
    // NFTRegistry specific methods
    function register(string calldata label, address owner) external;
}
