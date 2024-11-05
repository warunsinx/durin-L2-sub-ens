// ***********************************************
// ▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▄▖ ▗▖  ▗▖▗▄▄▄▖
// ▐▛▚▖▐▌▐▌ ▐▌▐▛▚▞▜▌▐▌   ▐▌     █ ▐▌ ▐▌▐▛▚▖▐▌▐▌
// ▐▌ ▝▜▌▐▛▀▜▌▐▌  ▐▌▐▛▀▀▘ ▝▀▚▖  █ ▐▌ ▐▌▐▌ ▝▜▌▐▛▀▀▘
// ▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌▐▙▄▄▖▗▄▄▞▘  █ ▝▚▄▞▘▐▌  ▐▌▐▙▄▄▖
// ***********************************************

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @author darianb.eth + Unruggable
/// @custom:project Durin
/// @custom:company NameStone

import "./L2Registry.sol";

contract L2RegistryFactory {
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
        // Deploy new L2Registry using CREATE
        L2Registry registry = new L2Registry(name, symbol, baseUri);

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
