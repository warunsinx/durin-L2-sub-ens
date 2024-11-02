// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTRegistry.sol";

contract NFTRegistryFactory {
    event RegistryDeployed(
        address registryAddress,
        string name,
        string symbol,
        string baseUri
    );

    function deployRegistry(
        string memory name,
        string memory symbol,
        string memory baseUri,
        bytes32 salt
    ) public returns (address) {
        // Generate creation code with constructor arguments
        bytes memory creationCode = abi.encodePacked(
            type(NFTRegistry).creationCode,
            abi.encode(name, symbol, baseUri)
        );

        // Deploy with CREATE2
        address registryAddress;
        assembly {
            registryAddress := create2(
                0, // value
                add(creationCode, 0x20), // bytecode
                mload(creationCode), // length
                salt // salt
            )
        }

        require(registryAddress != address(0), "Failed to deploy Registry");

        emit RegistryDeployed(registryAddress, name, symbol, baseUri);
        return registryAddress;
    }

    function computeAddress(
        string memory name,
        string memory symbol,
        string memory baseUri,
        bytes32 salt
    ) public view returns (address) {
        bytes memory creationCode = abi.encodePacked(
            type(NFTRegistry).creationCode,
            abi.encode(name, symbol, baseUri)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(creationCode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
