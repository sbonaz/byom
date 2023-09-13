// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "node_modules/@thirdweb-dev/contracts/extension/ContractMetadata.sol";

/*
     a simple messaging contract where users can send msgs to the contract, 
     and the owner of the contract can read these msgs.
     */
contract RecepteurDeMessages is ContractMetadata {
    // +State Variable:
    /* This variable stores the address of the owner of the contract. 
    The public keyword allows other contracts and external parties to read this variable.
     */
    address public owner;
    string[] public messagesList;

    // +Events
    /* The following event is emitted whenever someone sends msg to the contract. 
        It records the address of the sender and the msg sent in an array stored on the contract.
        if we want to find all MessageReceived events where a specific address (e.g., 0x123abc) sent msgs, 
        we can efficiently query for events with that indexed address as a filter criterion.
    */
    event MessageReceived(address indexed msgSender, string message);
    /* 
        The second event below is emitted when the owner retrieves msgs from the contract. 
        It records the owner's address and the msg retrieved.
    */
    event MessageRetrieved(address indexed owner, string message);

    // +Modifier
    /*  
    This is a custom modifier that restricts access to certain functions. 
    Only the owner of the contract can call functions with this modifier.
     If anyone else tries to call them, they will receive an error message.
    */
    modifier OnlyOwner() {
        require(msg.sender == owner, "Only Owner can read a message");
        _;
    }

    // +Constructor
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

    // +Sending message function
    /*  
     Anyone can send a message to the messagesList (held by the contract)
     */
    function sendMsg(string memory message) public {
        messagesList.push(message);
        emit MessageReceived(msg.sender, message);
    }

    // +Counting msgs
    function getMsgCount() public view returns (uint256) {
        return messagesList.length;
    }

    // +Reteieving message function
    /* 
    It checks that the messageList[] is not empty, 
    and if so, it transfers the msg to the owner's address.
    */
    function readMsg(
        uint256 index
    ) public view OnlyOwner returns (string memory) {
        require(index < messagesList.length, " index is outbound");
        return (messagesList[index]);
    }
}
