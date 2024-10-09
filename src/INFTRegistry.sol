/// @author darianb.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INFTRegistry {
    // Errors
    error Unauthorized();
    error TokenExpired(bytes32 labelhash, uint64 expiry);

    // Events
    event Registered(string label, address owner);
    event TextChanged(bytes32 indexed labelhash, string key, string value);
    event AddrChanged(bytes32 indexed labelhash, uint256 coinType, bytes value);
    event ContenthashChanged(bytes32 indexed labelhash, bytes value);

    // Structs
    struct Text {
        string key;
        string value;
    }
    struct Addr {
        uint256 coinType;
        bytes value;
    }

    // ERC721 methods
    function ownerOf(uint256 tokenId) external view returns (address);

    // AccessControl methods
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // NFTRegistry specific methods
    function totalSupply() external view returns (uint256);
    function baseUri() external view returns (string memory);
    function addRegistrar(address registrar) external;
    function removeRegistrar(address registrar) external;
    function register(string calldata label, address owner, uint64 expiry) external;
    function addr(bytes32 labelhash) external view returns (address);
    function addr(bytes32 labelhash, uint256 cointype) external view returns (bytes memory);
    function text(bytes32 labelhash, string calldata key) external view returns (string memory);
    function contenthash(bytes32 labelhash) external view returns (bytes memory);
    function getExpiry(bytes32 labelhash) external view returns (uint64);
    function available(uint256 tokenId) external view returns (bool);
    function labelFor(bytes32 labelhash) external view returns (string memory);
    function setBaseURI(string memory _baseUri) external;
    function setAddr(bytes32 labelhash, uint256 coinType, bytes calldata value) external;
    function setText(bytes32 labelhash, string calldata key, string calldata value) external;
    function setContenthash(bytes32 labelhash, bytes calldata value) external;
    function setExpiry(bytes32 labelhash, uint64 expiry) external;
    function setRecords(
        bytes32 labelhash,
        Text[] calldata texts,
        Addr[] calldata addrs,
        bytes[] calldata chash
    ) external;
}