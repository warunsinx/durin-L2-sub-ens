/// @author premm.eth (Unruggable)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StringUtils} from "./ens-utils/StringUtils.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {BytesUtilsSub} from "./utils/BytesUtilsSub.sol";
import {INFTRegistry} from "./INFTRegistry.sol";
import {Balances} from "./Balances.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

error CommitmentTooNew(bytes32 commitment);
error CommitmentTooOld(bytes32 commitment);
error DurationTooShort(uint256 duration);
error ResolverRequiredWhenDataSupplied();
error UnexpiredCommitmentExists(bytes32 commitment);
error InsufficientValue();
error UnauthorizedAddress(uint256 tokenId);
error MaxCommitmentAgeTooLow();
error MaxCommitmentAgeTooHigh();
error WrongNumberOfChars(string label);
error NoPricingData();
error CannotSetNewCharLengthAmounts();
error InvalidDuration(uint256 duration);
error LabelTooShort();
error LabelTooLong();

error ERC721NonexistentToken(uint256 tokenId);

contract NFTRegistrar is Balances /* AccessControl */ {
    using StringUtils for string;
    using Address for address payable;
    using BytesUtilsSub for bytes;

    uint64 private constant MAX_EXPIRY = type(uint64).max;
    uint256 public immutable minCommitmentAge;
    uint256 public immutable maxCommitmentAge;

    // target registry
    INFTRegistry public immutable targetRegistry;

    // Chainlink oracle address
    IAggregatorInterface public usdOracle;

    // The pricing and character requirements for registrations.
    uint64 public minRegistrationDuration;
    uint64 public maxRegistrationDuration;
    uint16 public minChars;
    uint16 public maxChars;
    uint256[] public charAmounts;

    mapping(bytes32 => uint256) public commitments;

    mapping(address wallet => uint256) public freeRegistrations;

    // the maximum number of registrstions that can be made for free.
    uint256 public maxFreeRegistrations;

    constructor(
        INFTRegistry _registry,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        IAggregatorInterface _usdOracle
    ) {
        targetRegistry = _registry;

        if (_maxCommitmentAge <= _minCommitmentAge) {
            revert MaxCommitmentAgeTooLow();
        }

        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;

        // Set the oracle address.
        usdOracle = _usdOracle;

        // Grant the contract deployer the default admin role and the admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // a setter function for the maxFreeRegistrations
    function setMaxFreeRegistrations(
        uint256 _maxFreeRegistrations
    ) public onlyRole(ADMIN_ROLE) {
        maxFreeRegistrations = _maxFreeRegistrations;
    }

    // a way to update the balance of free registrations for a batch of addresses
    function updateFreeRegistrations(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) public onlyRole(ADMIN_ROLE) {
        require(
            addresses.length == amounts.length,
            "Arrays must be the same length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            freeRegistrations[addresses[i]] = amounts[i];
        }
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
        uint256 duration
    ) public payable {
        // Check to make sure the duration is between the min and max.
        if (
            duration < minRegistrationDuration ||
            duration > maxRegistrationDuration
        ) {
            revert InvalidDuration(duration);
        }

        // Check to make sure the label is a valid length.
        if (!validLength(label)) {
            revert WrongNumberOfChars(label);
        }

        // Get the price for the duration.
        (uint256 price, ) = rentPrice(label, duration);

        // If the price is zero increment the free registration count.
        if (price == 0) {
            // If either the msg.sender or the owner's balance of free names
            // are greater than maxFreeRegistrations then revert.
            if (
                freeRegistrations[msg.sender] >= maxFreeRegistrations ||
                freeRegistrations[owner] >= maxFreeRegistrations
            ) {
                revert("Max free registrations exceeded");
            }

            // If the msg.sender and the owner are the same than just update the msg.sender's balance.
            if (msg.sender == owner) {
                freeRegistrations[msg.sender] += 1;
            } else {
                // If the msg.sender and the owner are different than update both balances.
                freeRegistrations[msg.sender] += 1;
                freeRegistrations[owner] += 1;
            }
        }

        // Check to make sure the caller sent enough Eth.
        if (msg.value < price) {
            revert InsufficientValue();
        }

        // use setLabel to register the label
        targetRegistry.register(
            label,
            owner,
            uint64(block.timestamp + duration)
        );

        // Because the oracle can return a slightly different value then what was estimated
        // we can overestimate the price and then return any difference.
        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }
    }

    // renew function that uses setExpiry to renew a label
    function renew(string memory label, uint256 duration) public payable {
        // make a tokenId from the label
        uint256 tokenId = uint256(keccak256(bytes(label)));

        // get the expiry data for tokenId
        uint64 expiry = targetRegistry.getExpiry(tokenId);

        // make sure only the owner of the label is the caller.
        if (msg.sender != targetRegistry.ownerOf(tokenId)) {
            revert UnauthorizedAddress(tokenId);
        }

        // Check to make sure the duration is between the min and max.
        if (
            duration < minRegistrationDuration ||
            duration > maxRegistrationDuration
        ) {
            revert InvalidDuration(duration);
        }

        // Get the price for the duration.
        (uint256 price, ) = rentPrice(label, duration);

        // Check to make sure the caller sent enough Eth.
        if (msg.value < price) {
            revert InsufficientValue();
        }

        // use setExpiry to renew the label
        targetRegistry.setExpiry(tokenId, uint64(expiry + duration));

        // If more Eth was sent than the price then return the difference.
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
        uint256 duration
    ) public view returns (uint256 weiPrice, uint256 usdPrice) {
        uint256 labelLength = label.strlen();

        // Get the length of the charAmounts array.
        uint256 charAmountsLength = charAmounts.length;

        // The price of the length of the label in USD/sec. (with 18 digits of precision).
        uint256 unitPrice;

        if (charAmountsLength > 0) {
            // Check to make sure the price for labelLength exists.
            // If not use the default price charAmounts[0].
            if (labelLength < charAmountsLength) {
                // Get the unit price, i.e. the price in USD/sec, for the length of
                // the label. If there is not a price set then use the defualt amount.
                unitPrice = charAmounts[labelLength];

                // If the unit price is 0 then use the default amount.
                if (unitPrice == 0) {
                    unitPrice = charAmounts[0];
                }
            } else {
                // Get the unit price, i.e. the price in USD/sec using the defualt amount.
                unitPrice = charAmounts[0];
            }
        } else {
            //If there is no pricing data, return 0, i.e. free.
            return (0, 0);
        }

        // Convert the unit price from USD to Wei.
        return (_usdToWei(unitPrice * duration), unitPrice * duration);
    }

    /**
     * @notice checkes to see if the length of the label is greater than the min. and less than the max.
     * @param label Label as a string, e.g. "vault" or vault.vitalik.eth.
     */

    function validLength(string memory label) internal view returns (bool) {
        // The label is valid if the number of characters of the label is greater than the
        // minimum and the less than the maximum or the maximum is 0, return true.
        if (label.strlen() >= minChars) {
            // If the maximum characters is set then check to make sure the label is
            // shorter or equal to it.
            if (maxChars != 0 && label.strlen() > maxChars) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    }

    // create a function to set the usd oracle address
    function setUSDOracle(address _oracle) public onlyRole(ADMIN_ROLE) {
        usdOracle = IAggregatorInterface(_oracle);
    }

    /**
     * @notice Set the pricing for subnames of the parent name.
     * @param _minRegistrationDuration The minimum duration a name can be registered for.
     * @param _maxRegistrationDuration The maximum duration a name can be registered for.
     * @param _minChars The minimum length a name can be.
     * @param _maxChars The maximum length a name can be.
     */

    function setParams(
        uint64 _minRegistrationDuration,
        uint64 _maxRegistrationDuration,
        uint16 _minChars,
        uint16 _maxChars
    ) public onlyRole(ADMIN_ROLE) {
        // Set the pricing for subnames of the parent node.
        minRegistrationDuration = _minRegistrationDuration;
        maxRegistrationDuration = _maxRegistrationDuration;
        minChars = _minChars;
        maxChars = _maxChars;
    }

    /**
     * @notice Set the pricing for subname lengths.
     * @param _charAmounts An array of amounst for each characer length.
     */

    function setPricingForAllLengths(
        uint256[] calldata _charAmounts
    ) public onlyRole(ADMIN_ROLE) {
        // Clear the old dynamic array out
        delete charAmounts;

        // Set the pricing for subnames of the parent node.
        charAmounts = _charAmounts;
    }

    /**
     * @notice Get the price for a single character length, e.g. three characters.
     * @param charLength The character length, e.g. 3 would be for three characters. Use 0 for the default amount.
     */
    function getPriceDataForLength(
        uint16 charLength
    ) public view returns (uint256) {
        return charAmounts[charLength];
    }

    /**
     * @notice Set a price for a single character length, e.g. three characters.
     * @param charLength The character length, e.g. 3 would be for three characters. Use 0 for the default amount.
     * @param charAmount The amount in USD/year for a character count, e.g. amount for three characters.
     */
    function updatePriceForCharLength(
        uint16 charLength,
        uint256 charAmount
    ) public onlyRole(ADMIN_ROLE) {
        // Check that the charLength is not greater than the last index of the charAmounts array.
        if (charLength > charAmounts.length - 1) {
            revert CannotSetNewCharLengthAmounts();
        }
        charAmounts[charLength] = charAmount;
    }

    /**
     * @notice Adds a price for the next character length, e.g. three characters.
     * @param charAmount The amount in USD/sec. (with 18 digits of precision)
     * for a character count, e.g. amount for three characters.
     */
    function addNextPriceForCharLength(
        uint256 charAmount
    ) public onlyRole(ADMIN_ROLE) {
        charAmounts.push(charAmount);
    }

    /**
     * @notice Get the last length for a character length that has a price (can be 0), e.g. three characters.
     * @return The length of the last character length that was set.
     */
    function getLastCharIndex() public view returns (uint256) {
        return charAmounts.length - 1;
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

    function _burnCommitment(bytes32 commitment) internal {
        // Require an old enough commitment.
        if (commitments[commitment] + minCommitmentAge > block.timestamp) {
            revert CommitmentTooNew(commitment);
        }

        // If the commitment is too old, or the label is registered, stop
        if (commitments[commitment] + maxCommitmentAge <= block.timestamp) {
            revert CommitmentTooOld(commitment);
        }

        delete (commitments[commitment]);
    }
}
