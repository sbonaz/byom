// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
 Extensions that will be detected on BYOMfg at build time
    ✔️ ERC20
    ✔️ ERC20Burnable
    ✔️ ERC20Mintable
    ✔️ ERC20BatchMintable
    ✔️ ERC20SignatureMintable
    ✔️ ERC20Permit
    ✔️ PlatformFee
    ✔️ PrimarySale
    ✔️ Permissions
    ✔️ PermissionsEnumerable
    ✔️ ContractMetadata
    ✔️ Gasless
*/

import {TokenERC20} from "node_modules/@Thirdweb-dev/contracts/prebuilts/token/TokenERC20.sol";

contract BYOMFr is TokenERC20 {
    /// +types
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.1. CUSTOM TYPES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // Custom types definition for metadata
    struct Author {
        address authorAddress;
        string externalLink;
    }

    struct ModuleMetadata {
        string title; // Changed to string from bytes32
        Author author;
        string version; // Changed to string from bytes32
        uint64 publishedAt;
        string externalLink; // Changed to string
    }

    /// +immutables and constantes
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.2.IMMUTABLES / CONSTANTES  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; // cbdc later on

    // Declaring constants for metadata
    address private immutable i_owner;
    string private constant NAME = "BYOM France";
    string private constant AUTHOR_URL = "http://www.byom.fr";
    string private constant VERSION = "0.0.1";
    uint64 private constant TIMESTAMP = 3479831479814;
    string private constant CONTRACT_URL = "http://www.byom.fr";

    ModuleMetadata public META_DATA;

    // list of ROLES (leveraging : Abstract account / abstract wallet / accountFactory which handlles the user login)
    enum Role {
        CLIENT_ROLE,
        MERCHANT_ROLE,
        PoS_ROLE,
        AGEANT_ROLE,
        AUTHORITY_ROLE,
        AMBASSADOR_ROLE,
        SANCTIONER_ROLE,
        AUDITOR_ROLE,
        ADMIN_ROLE,
        SUPPORT_ROLE,
        POR_ROLE
    }

    /// +variables
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.3. STATE VARIABLES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    address _defaultAdmin; // will be sent for initializing TokenERC20
    bool private initialized; // Flag to track contract initialization
    address public accountToCreate;
    Role public roleAssigned;

    // Native subnet currency for compliant DeFi
    uint256 public subnetCurrencyDecimals;
    uint256 public subnetCurrencyPeg;
    uint256 public subnetCurrencyPegRate;

    // Dictionary
    mapping(Role => bytes32) public roleToBytes32;
    mapping(address => bytes32) public addressToRoleHash;
    // List role hashes
    bytes32[] public roleHashes;

    /// +errors
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.4. E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // following errors provide information about why an operation failed.
    error AlreadyInitialized();
    error NotOwner();
    error Unauthorized();
    error ZeroAccount();
    error ZeroAddress();
    error SameAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error MiniAmountNotOk();

    /// +events    (usage: emit eventName();)
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.5. E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    event NewAccountCreated(address _newAccount, Role _newAcoountRole);
    event withdrawalComplet(address _from, uint256 _amount);
    event DepositRecieved(address _to, uint256 _amount);
    event TransferComplet(address _to, uint256 _amount);
    event TransferOrdered(
        address sender,
        address _to,
        uint256 _amount,
        string _reason
    );
    event TransferPending(
        address _from,
        address _to,
        uint256 _amount,
        string _reason
    );

    /// +modifiers
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.6.  M O D I F I E R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    modifier canInitialize(address _subnetNewOwner) {
        if (!initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
    modifier addressCheck(address _from, address _to) {
        if (_from == _to) {
            revert SameAddress();
        }
        if (_to == address(0) || _from == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    // following modifier exists in Ownable.sol
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // Not zero account
    modifier accountCreated(address _account, Role _accountRole) {
        if (_account == address(0) || _accountRole == Role(0x0)) {
            revert ZeroAccount();
        }
        _;
    }

    /*
    
    modifier onlySubnetAdmin() {
        require(msg.sender == _defaultAdmin, "NotSubnetAdmin");
        _;
    }

    modifier minimumRequire() {
        if (msg.value.getConversionRate() < MINIMUM_USD)
            revert MiniAmountNotOk();
        _;
    }

    */

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.1. CONSTRUCTOR @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    // The construtor is useless if this contract is deployed through a proxy, on Thirdweb plateform for instance.

    constructor() {
        i_owner = msg.sender;

        // init to assign this contract specific immutable variables
        META_DATA = ModuleMetadata(
            NAME,
            Author(i_owner, AUTHOR_URL),
            VERSION,
            TIMESTAMP,
            CONTRACT_URL
        );

        _defaultAdmin = i_owner;

        // Initialize role hashes array
        roleHashes = [
            keccak256("CLIENT_ROLE"),
            keccak256("MERCHANT_ROLE"),
            keccak256("PoS_ROLE"),
            keccak256("AGEANT_ROLE"),
            keccak256("AUTHORITY_ROLE"),
            keccak256("AMBASSADOR_ROLE"),
            keccak256("SANCTIONER_ROLE"),
            keccak256("AUDITOR_ROLE"),
            keccak256("ADMIN_ROLE"),
            keccak256("SUPPORT_ROLE"),
            keccak256("POR_ROLE") // Proof of Reserve
        ];

        // grantRole(roleHashes[8], i_owner);

        // intit TokenERC20
        TokenERC20(_defaultAdmin);
    }

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.2. EXTENDED METADATA @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // Function to use the `ContractMetadata` extension.
    /**
     * This function returns who is authorized to set the metadata for this contract.
     */
    function _canSetContractURI() internal view virtual returns (bool) {
        return msg.sender == i_owner;
    }

    function contractType()
        external
        pure
        override
        returns (bytes32 MODULE_TYPE)
    {
        return (MODULE_TYPE); // Where this is from?
    }

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.3. ROYALTY @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.4. ROLES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // setting up custom roles for subnet's abstract accounts.
    // the default admin role is from "PermissionEnumerable" which provides role-based access control.

    function createAccount(
        address _newAccount,
        Role _newAccountRole
    ) public onlyOwner accountCreated(_newAccount, _newAccountRole) {
        // Get the hash of the desired role
        bytes32 roleHash = roleToBytes32[_newAccountRole];
        // DEFAULT_ADMIN_ROLE is not assigneable
        require(roleHash != bytes32(0x0), "Invalid role");
        // Check if the role hash is in the allowed list
        require(
            roleHashFound(roleHash),
            "Role hash not found in the allowed list"
        );
        // Assign the role to the provided address
        addressToRoleHash[_newAccount] = roleHash;
        // Log the newly created account
        emit NewAccountCreated(_newAccount, _newAccountRole);
    }

    // Function to check if a role hash is in the allowed list
    function roleHashFound(bytes32 _roleHash) internal view returns (bool) {
        for (uint256 i = 0; i < roleHashes.length; i++) {
            if (roleHashes[i] == _roleHash) {
                return true;
            }
        }
        return false;
    }
}
