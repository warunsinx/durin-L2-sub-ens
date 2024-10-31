// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTRegistry.sol";
import "../src/NFTRegistrar.sol";

contract NFTRegistrarTest is Test {
    NFTRegistry public registry;
    NFTRegistrar public registrar;

    address public admin = address(1);
    address public user1 = address(2);

    event AddressWithdrew(address indexed _address, uint256 indexed amount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event NameRegistered(
        string indexed label,
        address indexed owner,
        uint256 price
    );

    function setUp() public {
        vm.startPrank(admin);
        registry = new NFTRegistry("TestNames", "TEST", "https://test.uri/");
        registrar = new NFTRegistrar(INFTRegistry(address(registry)));
        registry.addRegistrar(address(registrar));
        vm.stopPrank();
    }

    function test_Available() public {
        string memory label = "test";
        bytes32 labelhash = keccak256(abi.encodePacked(label));

        // Should be available before registration
        assertTrue(registrar.available(uint256(labelhash)));

        // Register the name
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        registrar.register{value: 0.01 ether}(label, user1);

        // Should not be available after registration
        assertFalse(registrar.available(uint256(labelhash)));
    }

    function test_SetPrice() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit PriceUpdated(0, 0.02 ether);
        registrar.setPrice(0.02 ether);
        assertEq(registrar.namePrice(), 0.02 ether);
    }

    function test_Withdraw() public {
        // Set price and register a name to get some funds in the contract
        vm.prank(admin);
        registrar.setPrice(0.01 ether);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        registrar.register{value: 0.01 ether}("test", user1);

        // Test withdrawal
        uint256 initialBalance = admin.balance;
        vm.prank(admin);
        registrar.withdraw(0.01 ether);
        assertEq(admin.balance - initialBalance, 0.01 ether);
    }

    function testFuzz_Register(
        string calldata label,
        uint256 paymentAmount
    ) public {
        vm.assume(bytes(label).length > 0);
        vm.assume(bytes(label).length < 100);
        vm.assume(paymentAmount >= 0.01 ether && paymentAmount <= 1 ether);

        vm.prank(admin);
        registrar.setPrice(0.01 ether);

        vm.deal(user1, paymentAmount);
        vm.prank(user1);
        registrar.register{value: paymentAmount}(label, user1);

        // Verify registration
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        assertEq(registry.ownerOf(uint256(labelhash)), user1);

        // Verify refund if overpaid
        if (paymentAmount > 0.01 ether) {
            assertEq(user1.balance, paymentAmount - 0.01 ether);
        }
    }
}
