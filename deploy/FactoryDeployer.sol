// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {CREATE2} from "@openzeppelin/contracts/utils/Create2.sol";
import "src/NFTRegistryFactory.sol";

contract FactoryDeployer is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get the bytecode of the factory
        bytes memory bytecode = type(NFTRegistryFactory).creationCode;

        // Use a fixed salt for consistent addresses across chains
        bytes32 salt = keccak256(abi.encodePacked("NFTRegistryFactory_v1"));

        // Calculate the expected address
        address expectedAddress = CREATE2.computeAddress(
            salt,
            keccak256(bytecode),
            msg.sender
        );
        console.log("Expected Factory address:", expectedAddress);

        // Deploy the factory using CREATE2
        assembly {
            factoryAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }
        require(factoryAddress != address(0), "Create2: Failed on deploy");

        console.log("Actual deployed address:", factoryAddress);
        require(factoryAddress == expectedAddress, "Address mismatch");

        vm.stopBroadcast();
    }
}
