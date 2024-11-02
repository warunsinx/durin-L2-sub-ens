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
        string memory baseUri
    ) public returns (address) {
        // Deploy new NFTRegistry using CREATE
        NFTRegistry registry = new NFTRegistry(name, symbol, baseUri);

        emit RegistryDeployed(address(registry), name, symbol, baseUri);
        return address(registry);
    }
}
