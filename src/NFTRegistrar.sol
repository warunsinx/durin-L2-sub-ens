/// @author premm.eth (Unruggable)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StringUtils} from "./utils/StringUtils.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {BytesUtilsSub} from "./utils/BytesUtilsSub.sol";
import {INFTRegistry} from "./INFTRegistry.sol";
import {Balances} from "./Balances.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

error DurationTooShort(uint256 duration);
error ResolverRequiredWhenDataSupplied();
error InsufficientValue();
error UnauthorizedAddress(uint256 tokenId);
error NoPricingData();

error ERC721NonexistentToken(uint256 tokenId);

contract NFTRegistrar is Balances /* AccessControl */ {
    using StringUtils for string;
    using Address for address payable;
    using BytesUtilsSub for bytes;

    // target registry
    INFTRegistry public immutable targetRegistry;

    // Chainlink oracle address
    IAggregatorInterface public usdOracle;

    // The pricing and character requirements for registrations.
    uint256 public namePrice;

    constructor(INFTRegistry _registry, IAggregatorInterface _usdOracle) {
        targetRegistry = _registry;

        // Set the oracle address.
        usdOracle = _usdOracle;

        // Grant the contract deployer the default admin role and the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Checks if a given tokenId is available for registration.
     * @param tokenId The tokenId to check.
     * @return available True if the tokenId is available, false otherwise.
     */
    function available(uint256 tokenId) external view returns (bool) {
        try targetRegistry.ownerOf(tokenId) returns (address) {
            // If ownerOf doesn't revert, the token exists, so it is not available
            return false;
        } catch (bytes memory reason) {
            // Catch the specific custom error using error signature comparison
            if (
                keccak256(reason) ==
                keccak256(
                    abi.encodeWithSelector(
                        ERC721NonexistentToken.selector,
                        tokenId
                    )
                )
            ) {
                // Token does not exist (minting has not happened), it is available
                return true;
            } else {
                // Re-throw if it's another type of error
                revert(string(reason));
            }
        }
    }

    // a register function that uses mint to register a label
    function register(
        string memory label,
        address owner,
    ) public payable {
        // Get the price for the duration.
        (uint256 price, ) = rentPrice(label);

        // Check to make sure the caller sent enough Eth.
        if (msg.value < price) {
            revert InsufficientValue();
        }

        // use setLabel to register the label
        targetRegistry.register(
            label,
            owner,
            uint256(block.timestamp + duration)
        );

        // Because the oracle can return a slightly different value then what was estimated
        // we can overestimate the price and then return any difference.
        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }
    }


    /**
     * @notice Gets the total cost of rent in wei, from the unitPrice, i.e. USD, and duration.
     * @param duration The amount of time the label will be rented for/extended in years.
     * @return weiPrice The rent price for the duration in Wei
     * @return usdPrice The rent price for the duration in USD
     */

    function rentPrice(
        string memory label,
    ) public view returns (uint256 weiPrice, uint256 usdPrice) {

        // Convert the unit price from USD to Wei.
        return (_usdToWei(namePrice), namePrice);
    }

    // create a function to set the usd oracle address
    function setUSDOracle(address _oracle) public onlyRole(ADMIN_ROLE) {
        usdOracle = IAggregatorInterface(_oracle);
    }

  
    /**
     * @notice Set a price for a name, e.g. three characters.
     * @param charAmount The amount in USD/Sec for a name
     */
    function updatePrice(
        uint256 price
    ) public onlyRole(ADMIN_ROLE) {
        // Check that the charLength is not greater than the last index of the charAmounts array.
        namePrice = price;
    }

    /* Internal functions */

    /**
     * @dev Converts USD to Wei.
     * @param amount The amount of USD to be converted to Wei.
     * @return The amount of Wei.
     */
    function _usdToWei(uint256 amount) internal view returns (uint256) {
        // Get the price of ETH in USD (with 8 digits of precision) from the oracle.
        uint256 ethPrice = uint256(usdOracle.latestAnswer());

        // Convert the amount of USD (with 18 digits of precision) to Wei.
        return (amount * 1e8) / ethPrice;
    }

}
