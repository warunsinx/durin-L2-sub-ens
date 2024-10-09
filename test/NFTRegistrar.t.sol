// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BytesUtilsSub} from "../src/utils/BytesUtilsSub.sol";
import "../src/NFTRegistrar.sol";
import {NFTRegistry} from "../src/NFTRegistry.sol";
import {USDOracleMock} from "../src/mocks/USDOracleMock.sol";
import {INFTRegistry} from "../src/INFTRegistry.sol";

error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

contract NFTRegistrarTest is Test {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    bytes32 public constant SUBDOMAIN_ISSUER_ROLE =
        keccak256("SUBDOMAIN_ISSUER_ROLE");

    using BytesUtilsSub for bytes;

    uint64 twoYears = 63072000; // Approximately 2 years
    uint64 oneYear = 31536000; // A year in seconds.
    uint64 oneMonth = 2592000; // A month in seconds.
    uint64 oneDay = 86400; // A day in seconds.

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;
    address account3 = 0x0000000000000000000000000000000000005713;
    address hacker = 0x0000000000000000000000000000000000006874;
    address resolver = 0x0000000000000000000000000000000000007365;
    address resolver2 = 0x0000000000000000000000000000000000008246;
    address renewalController = account3;

    struct Text {
        string key;
        string value;
    }
    struct Addr {
        uint256 coinType;
        bytes value;
    }
    struct Cointype {
        uint256 key;
        string value;
    }

    uint64 public constant startTime = 1641070800;

    NFTRegistry polyRegistry;
    V2PolyRegistrar registrar;

    USDOracleMock usdOracle;

    function setUp() public {
        vm.warp(startTime);
        vm.startPrank(account);

        vm.deal(account, 100 ether);

        polyRegistry = new NFTRegistry("XCTENS", "XCT", "https://xctens.com/");

        // make a token of the label "name".
        uint256 token_name = polyRegistry.tokenFor("name");

        // Setup a dummy oracle
        usdOracle = new USDOracleMock();

        // Create a new V2Registrar for the "name" label registry
        registrar = new V2PolyRegistrar(
            INFTRegistry(address(polyRegistry)), // Target registry
            60,
            604800, // A week in seconds
            usdOracle // USD Oracle address
        );

        // Set account as a registrar, so we can register names directly.
        polyRegistry.addRegistrar(account);

        // Register the "name" label directly into the registry.
        polyRegistry.register("name", account, startTime + oneYear);

        // check to make sure that name was registered.
        assertEq(polyRegistry.ownerOf(token_name), account);

        // Add the registrar as an additional registrar for the registry.
        polyRegistry.addRegistrar(address(registrar));

        // Set params for the L2 Eth Registrar.
        registrar.setParams(
            oneMonth, // Minimum length of registration
            type(uint64).max, // No maximum length of time.
            3, // Minimum three characters
            255 // Maximum 255 characters
        );

        // Set the pricing for the name registrar.
        // Not all the values have been defined, which has been done to make sure that nothing
        // breaks even if one is not defined.
        uint256[] memory charAmounts = new uint256[](4);
        charAmounts[0] = 158548959918; // (≈$5/year) calculated as $/sec with 18 decimals.
        charAmounts[1] = 158548959918;
        charAmounts[2] = 0;

        registrar.setPricingForAllLengths(charAmounts);
    }

    // Create a Subheading using an empty function.
    function test1000________________________________________________________________________________()
        public
    {}
    function test2000__________________________V2_REGISTRAR_TESTS____________________________________()
        public
    {}
    function test3000________________________________________________________________________________()
        public
    {}

    function test_001____rentPrice___________________RentPriceWasSetCorrectly()
        public
        view
    {
        // Get the price for renewing the label for a year.
        (uint256 weiAmount, ) = registrar.rentPrice("abc", oneYear);

        // Get the USD price of Eth from the oracle.
        int256 ethPrice = usdOracle.latestPrice();
        // Check to make sure the price is around $5/year.
        uint256 expectedPrice = (5 * 10 ** 26) / uint256(ethPrice);

        // Make sure the price is close to the expected price.
        assertTrue(weiAmount / 10 ** 10 == expectedPrice / 10 ** 10);
    }

    function test_002____rentPrice___________________DefaultPriceIsZero()
        public
    {
        uint256[] memory charAmountsNull = new uint256[](0);

        registrar.setPricingForAllLengths(charAmountsNull);

        // Make sure the price is zero.
        (uint256 weiAmount, uint256 usdAmount) = registrar.rentPrice(
            "abc",
            oneYear
        );

        // Check to make sure the price is zero.
        assertEq(weiAmount, 0);
        assertEq(usdAmount, 0);
    }

    function test_005____setParams___________________SetTheRegistrationParameters()
        public
    {
        registrar.setParams(3601, type(uint64).max, 2, 254);

        assertEq(registrar.minRegistrationDuration(), 3601);
        assertEq(registrar.maxRegistrationDuration(), type(uint64).max);
        assertEq(registrar.minChars(), 2);
        assertEq(registrar.maxChars(), 254);
    }

    function test_006____setPricingForAllLengths_____SetThePriceForAllLengthsOfNamesAtOneTime()
        public
    {
        // Set the pricing for the name registrar.
        // Note that there are 4 elements, but only the fist three have been defined.
        // This has been done to make sure that nothing breaks even if one is not defined.
        uint256[] memory charAmounts = new uint256[](4);
        charAmounts[0] = 158548959918; // (≈$5/year) calculated as $/sec with 18 decimals.
        charAmounts[1] = 158548959918;
        charAmounts[2] = 1;

        registrar.setPricingForAllLengths(charAmounts);
        assertEq(registrar.getPriceDataForLength(0), 158548959918);
        assertEq(registrar.getPriceDataForLength(1), 158548959918);
        assertEq(registrar.getPriceDataForLength(2), 1);
        assertEq(registrar.getPriceDataForLength(3), 0);
    }

    function test_007____getPriceDataForLength_______TheAmontForAnySetLengthOfName()
        public
    {
        // Add a price for the next character (4th character).
        registrar.addNextPriceForCharLength(317097919836);
        assertEq(registrar.getPriceDataForLength(uint16(4)), 317097919836);
    }

    function test_008____updatePriceForCharLength____UpdateThePriceOfANameLength()
        public
    {
        registrar.updatePriceForCharLength(3, 317097919836);

        assertEq(
            registrar.getPriceDataForLength(
                uint16(registrar.getLastCharIndex())
            ),
            317097919836
        );
    }

    function test_009____updatePriceForCharLength____RevertsIfLengthDoesntExist()
        public
    {
        // revert with error CannotSetNewCharLengthAmounts if the length doesn't exist.
        vm.expectRevert(
            abi.encodeWithSelector(CannotSetNewCharLengthAmounts.selector)
        );

        registrar.updatePriceForCharLength(12, 317097919836);
    }

    // Test function to get the last index of char amounts.
    function test_009____getLastCharIndex____________ReturnsTheLastIndexOfCharAmounts()
        public
    {
        // Add a price for the next character (4th character).
        registrar.addNextPriceForCharLength(317097919836);
        // Assert that the last character index is 4.
        assertEq(registrar.getLastCharIndex(), 4);
    }

    // Make sure a user can register a name with a commitment.
    function test_012____register______________________RegisterAName() public {
        // Save the balance of the account.
        uint256 balance = account.balance;

        // Register the name.
        registrar.register{value: 1 ether}("sub", account, oneYear);

        // Make the labelhash of the label.
        bytes32 labelhash = keccak256(bytes("sub"));

        // Check to make sure the owner of the name is the account.
        assertEq(account, polyRegistry.ownerOf(uint256(labelhash)));

        // Check to make sure the account balance has been reduced by 158548959918 * a year in seconds.
        assertEq(balance - 2696231746497081, account.balance);
    }

    // Make sure that after registering a name that it is no longer available.
    function test_013____available_____________________NameIsNoLongerAvailable()
        public
    {
        // Save the balance of the account.
        uint256 balance = account.balance;

        // Register the name.
        registrar.register{value: 1 ether}("sub", account, oneYear);

        // Make the labelhash of the label.
        bytes32 labelhash = keccak256(bytes("sub"));

        // Check to make sure the owner of the name is the account.
        assertEq(account, polyRegistry.ownerOf(uint256(labelhash)));

        // Check to make sure the account balance has been reduced by 158548959918 * a year in seconds.
        assertEq(balance - 2696231746497081, account.balance);

        // Check to make sure the name is no longer available.
        assertTrue(!registrar.available(uint256(labelhash)));
    }

    // Make sure that a name that has not been registered is available.
    function test_014____available_____________________NameIsAvailable()
        public
        view
    {
        // Make the labelhash of the label.
        bytes32 labelhash = keccak256(bytes("sub"));

        // Check to make sure the name is available.
        assertTrue(registrar.available(uint256(labelhash)));
    }

    // Make sure that the owner of the name can renew the name.
    function test_016____renew_________________________OwnerCanRenewTheName()
        public
    {
        // Save the balance of the account.
        uint256 balance = account.balance;

        // Register the name.
        registrar.register{value: 1 ether}("sub", account, oneYear);

        // Make the labelhash of the label.
        bytes32 labelhash = keccak256(bytes("sub"));

        // Check to make sure the owner of the name is the account.
        assertEq(account, polyRegistry.ownerOf(uint256(labelhash)));

        // Check to make sure the account balance has been reduced by 158548959918 * a year in seconds.
        assertEq(balance - 2696231746497081, account.balance);

        // Renew the name.
        registrar.renew{value: 1 ether}("sub", oneYear);

        // Get the expiry of the label.
        uint64 expiry = polyRegistry.getExpiry(uint256(labelhash));

        // Make sure the expiry of the name is now 2 years.
        assertEq(expiry, startTime + 2 * oneYear);
    }
}
