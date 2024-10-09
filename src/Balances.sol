//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract Balances is AccessControl {
    using Address for address payable;

    event AddressWithdrew(address indexed _address, uint256 indexed amount);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @notice A function to allow referrers, name owners, or the contract owner to withdraw.
     */

    function withdraw(uint256 amount) public onlyRole(ADMIN_ROLE) {
        //get the address of the sender
        address payable sender = payable(msg.sender);

        emit AddressWithdrew(sender, amount);

        // Send the amount to the contract owner's address.
        sender.sendValue(amount);
    }
}
