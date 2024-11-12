// ***********************************************
// ▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖▗▄▄▄▖▗▄▖ ▗▖  ▗▖▗▄▄▄▖
// ▐▛▚▖▐▌▐▌ ▐▌▐▛▚▞▜▌▐▌   ▐▌     █ ▐▌ ▐▌▐▛▚▖▐▌▐▌
// ▐▌ ▝▜▌▐▛▀▜▌▐▌  ▐▌▐▛▀▀▘ ▝▀▚▖  █ ▐▌ ▐▌▐▌ ▝▜▌▐▛▀▀▘
// ▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌▐▙▄▄▖▗▄▄▞▘  █ ▝▚▄▞▘▐▌  ▐▌▐▙▄▄▖
// ***********************************************

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @author darianb.eth
/// @custom:project Durin
/// @custom:company NameStone
/// @notice Factory contract for deploying new L2Registry instances
/// @dev Uses CREATE opcode for deterministic deployment of registry contracts

import "./L2Registry.sol";

/// @title L2Registry Factory
/// @notice Facilitates the deployment of new L2Registry instances with proper role configuration
/// @dev Handles deployment and initial role setup, then renounces factory control
contract L2RegistryFactory {
    /// @notice Emitted when a new registry is deployed
    /// @param registryAddress The address of the newly deployed registry
    /// @param name The name of the registry's ERC721 token
    /// @param symbol The symbol of the registry's ERC721 token
    /// @param baseUri The base URI for the registry's token metadata
    /// @param admin The address granted admin roles for the new registry
    event RegistryDeployed(
        address registryAddress,
        string name,
        string symbol,
        string baseUri,
        address admin
    );

    /// @notice Deploys a new L2Registry contract with specified parameters
    /// @param name The name for the registry's ERC721 token
    /// @param symbol The symbol for the registry's ERC721 token
    /// @param baseUri The base URI for the registry's token metadata
    /// @return address The address of the newly deployed registry
    /// @dev Handles complete deployment process including:
    ///      1. Contract deployment
    ///      2. Role assignment to caller
    ///      3. Role renunciation by factory
    function deployRegistry(
        string memory name,
        string memory symbol,
        string memory baseUri
    ) public returns (address) {
        // Deploy new L2Registry using CREATE
        L2Registry registry = new L2Registry(name, symbol, baseUri);

        // Grant admin roles to the caller
        // This allows the deployer to manage the registry
        registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), msg.sender);
        registry.grantRole(registry.ADMIN_ROLE(), msg.sender);

        // Renounce factory's admin roles
        // This ensures the factory cannot interfere with the registry after deployment
        registry.renounceRole(registry.DEFAULT_ADMIN_ROLE(), address(this));
        registry.renounceRole(registry.ADMIN_ROLE(), address(this));

        // Emit event for indexing and tracking purposes
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
