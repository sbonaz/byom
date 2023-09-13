pragma solidity ^0.8.0;

import "./Ownable.sol"; // Import the Ownable contract

contract YourContract is Ownable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    constructor() {
        _initialized = false; // Contract is not yet initialized;
        _initializing = false; // Contract is not initializing;
    }

    /**
     * @notice Initializes the contract and sets the owner.
     * @param _newOwner The address to set as the new owner of the contract.
     */
    function initialize(address _newOwner) external {
        require(!_initialized, "Already initialized");
        _setupOwner(_newOwner);
        _initialized = true;
    }

    // Override _canSetOwner to control who can set the owner during initialization
    function _canSetOwner() internal view override returns (bool) {
        // Add your custom logic here to restrict who can set the owner during initialization
        // For example, require(msg.sender == deployer) or any other condition you want
        return true; // Allow owner to set during initialization
    }
}
