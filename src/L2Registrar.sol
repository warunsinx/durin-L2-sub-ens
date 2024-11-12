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

import {StringUtils} from "./utils/StringUtils.sol";
import {BytesUtilsSub} from "./utils/BytesUtilsSub.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IL2Registry} from "./IL2Registry.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Thrown when the sent value is less than the required name price
error InsufficientValue();
/// @notice Thrown when attempting to interact with a non-existent token
error ERC721NonexistentToken(uint256 tokenId);

/// @title Registrar (for Layer 2)
/// @dev This is a simple registrar contract that is mean to be modified.
contract L2Registrar is AccessControl {
    using StringUtils for string;
    using Address for address payable;
    using BytesUtilsSub for bytes;

    /// @notice Emitted when an address withdraws funds from the contract
    /// @param _address The address that withdrew funds
    /// @param amount The amount withdrawn
    event AddressWithdrew(address indexed _address, uint256 indexed amount);

    /// @notice Emitted when the registration price is updated
    /// @param oldPrice The previous price
    /// @param newPrice The new price
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    /// @notice Emitted when a new name is registered
    /// @param label The registered name
    /// @param owner The owner of the newly registered name
    /// @param price The price paid for registration
    event NameRegistered(
        string indexed label,
        address indexed owner,
        uint256 price
    );

    /// @notice Role identifier for administrators who can withdraw funds and set prices
    /// @dev Calculated as keccak256("ADMIN_ROLE")
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Reference to the target registry contract
    /// @dev Immutable to save gas and prevent manipulation
    IL2Registry public immutable targetRegistry;

    /// @notice Current price for name registration
    /// @dev Can be modified by admins through setPrice()
    uint256 public namePrice;

    /// @notice Initializes the registrar with a registry contract and sets up admin roles
    /// @param _registry Address of the L2Registry contract
    /// @dev Grants DEFAULT_ADMIN_ROLE and ADMIN_ROLE to the contract deployer
    constructor(IL2Registry _registry) {
        targetRegistry = _registry;

        // Grant the contract deployer the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Checks if a given tokenId is available for registration
    /// @param tokenId The tokenId to check availability for
    /// @return available True if the tokenId can be registered, false if already taken
    /// @dev Uses try-catch to handle the ERC721NonexistentToken error
    function available(uint256 tokenId) external view returns (bool) {
        try targetRegistry.ownerOf(tokenId) returns (address) {
            // Token exists and has an owner
            return false;
        } catch (bytes memory reason) {
            // Check if the error is specifically ERC721NonexistentToken
            if (
                keccak256(reason) ==
                keccak256(
                    abi.encodeWithSelector(
                        ERC721NonexistentToken.selector,
                        tokenId
                    )
                )
            ) {
                // Token doesn't exist, so it's available
                return true;
            } else {
                // Propagate any other errors
                revert(string(reason));
            }
        }
    }

    /// @notice Registers a new name
    /// @param label The name to register
    /// @param owner The address that will own the name
    /// @dev Requires sufficient payment in ETH
    /// @dev Returns excess payment to sender
    function register(string memory label, address owner) public payable {
        // Verify sufficient payment
        if (msg.value < namePrice) {
            revert InsufficientValue();
        }

        // Register the name with the target registry
        targetRegistry.register(label, owner);

        // Refund any excess payment
        if (msg.value > namePrice) {
            payable(msg.sender).sendValue(msg.value - namePrice);
        }

        emit NameRegistered(label, owner, namePrice);
    }

    /// @notice Updates the price for name registration
    /// @param price The new price in native currency (ETH)
    /// @dev Only callable by addresses with ADMIN_ROLE
    function setPrice(uint256 price) public onlyRole(ADMIN_ROLE) {
        uint256 oldPrice = namePrice;
        namePrice = price;
        emit PriceUpdated(oldPrice, price);
    }

    /// @notice Allows admins to withdraw funds from the contract
    /// @param amount The amount of ETH to withdraw
    /// @dev Only callable by addresses with ADMIN_ROLE
    /// @dev Uses OpenZeppelin's Address.sendValue for safe transfers
    function withdraw(uint256 amount) public onlyRole(ADMIN_ROLE) {
        address payable sender = payable(msg.sender);

        emit AddressWithdrew(sender, amount);

        sender.sendValue(amount);
    }
}
