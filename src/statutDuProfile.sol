// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "node_modules/@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract ProfileStaStatutDuProfile is ContractMetadata {
    // Define a struct to store user status information
    struct Status {
        string statusMessage; // A string to hold the status message
        bool exists; // A boolean flag to indicate if the status exists
    }

    // Define two events to log when a status is created or updated
    event statusCreated(address indexed wallet, string status);
    event statusUpdated(address indexed wallet, string newStatus);

    // Mapping to associate each user's address with their Status struct
    mapping(address => Status) public userStatus;

    /**
     *  We store the contract owner (the deployer)'s address.
     *  Doing this is not necessary to use the `ContractMetadata` extension.
     */
    address public owner;

    // One time ran function
    constructor() {
        owner = msg.sender;
    }

    // Function to use the `ContractMetadata` extension.
    /**
     * This function returns who is authorized to set the metadata for this contract.
     */
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner;
    }

    // Function to create a new status for a user
    function createStatus(string memory initialStatus) public {
        // Ensure that a status does not already exist for the sender
        require(!userStatus[msg.sender].exists, "Status already exists");

        // Create a new Status struct and associate it with the sender's address
        userStatus[msg.sender] = Status({
            statusMessage: initialStatus,
            exists: true
        });

        // Emit an event to log the creation of the status
        emit statusCreated(msg.sender, initialStatus);
    }

    // Function to update an existing status for a user
    function updateStatus(string memory newStatus) public {
        // Ensure that a status exists for the sender
        require(userStatus[msg.sender].exists, "No status to update");

        // Update the existing Status struct with the new status message
        userStatus[msg.sender].statusMessage = newStatus;

        // Emit an event to log the update of the status
        emit statusUpdated(msg.sender, newStatus);
    }

    // function to get a wallet' status
    function getStatus(address wallet) public view returns (string memory) {
        require(userStatus[wallet].exists, "this status does not exist");
        return userStatus[wallet].statusMessage;
    }
}
