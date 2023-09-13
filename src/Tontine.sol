// SPDX-License-Identifier: MIT

// The Solidity compiler that should be used to compile the contract.
/* In this case, it's using version 0.8.10 or a compatible version.*/
pragma solidity ^0.8.10;

import "node_modules/@thirdweb-dev/contracts/extension/ContractMetadata.sol";

/*
     a simple financial contract where users can send funds to the contract, 
     and the owner of the contract can withdraw those funds.
     */
contract Tontine is ContractMetadata {
    // +State Variable:
    /* This variable stores the address of the owner of the contract. 
    The public keyword allows other contracts and external parties to read this variable.
     */
    address public owner;

    // +Events
    /* The following event is emitted whenever someone sends funds to the contract. 
        It records the address of the sender and the amount sent.
        the 'indexed' keyword is used when defining event parameters to indicate that a particular parameter should be indexed in the event logs. 
        This has significance when querying or filtering events, 
        as indexed parameters can be used as filter criteria to efficiently search for specific events.
        if we want to find all FundsReceived events where a specific address (e.g., 0x123abc) sent funds, 
        we can efficiently query for events with that indexed address as a filter criterion.
    */
    event FundsReceived(address indexed funder, uint256 amount);
    /* 
        This event is emitted when the owner withdraws funds from the contract. 
        It records the owner's address and the amount withdrawn.
    */
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // +Modifier
    /*  
    This is a custom modifier that restricts access to certain functions. 
    Only the owner of the contract can call functions with this modifier.
     If anyone else tries to call them, they will receive an error message.
    */
    modifier OnlyOwner() {
        require(msg.sender == owner, "Only Owner can withdraw");
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

    // + Funding
    /*  
     Anyone can send funds to a shared pool (the contract)
     */
    function Fund() public payable {
        require(msg.value > 0, " You must send funds");
        emit FundsReceived(msg.sender, msg.value);
    }

    // +withdraw
    /* 
    It checks that the contract's balance is greater than 0, 
    and if so, it transfers the entire contract balance to the owner's address.
    */
    function withdrawFunds() public OnlyOwner {
        uint256 contractBalance = address(this).balance; // balance at this contract's address
        require(contractBalance > 0, " No tip left"); // a fair check
        payable(owner).transfer(contractBalance); // functions payable() et transfer()
        emit FundsWithdrawn(owner, contractBalance);
    }

    function getBalance() public view returns (uint256) {
        return (address(this).balance);
    }
}
