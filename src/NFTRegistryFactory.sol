// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTRegistry.sol";

contract NFTRegistryFactory {
    event RegistryDeployed(
        address registryAddress,
        string name,
        string symbol,
        string baseUri,
        address admin
    );

    function deployRegistry(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) public returns (address) {
        // Deploy new NFTRegistry using CREATE
        NFTRegistry registry = new NFTRegistry(name, symbol, baseUri);

        // Grant admin roles to the caller
        registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), msg.sender);
        registry.grantRole(registry.ADMIN_ROLE(), msg.sender);

        // Renounce factory's admin roles
        registry.renounceRole(registry.DEFAULT_ADMIN_ROLE(), address(this));
        registry.renounceRole(registry.ADMIN_ROLE(), address(this));

        emit RegistryDeployed(
            address(registry),
            name,
            symbol,
            baseUri,
            msg.sender
        );
        return address(registry);
    }
}
