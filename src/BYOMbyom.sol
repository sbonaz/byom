// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// |@@@@@@@@@\  \@@\    /@@/ /@@@@@@@@@\   |@\@@\        /@@/@|
// |@@@@@@@@@@|  \@@\  /@@/ /@@@@@@@@@@@\  |@@\@@\      /@@/@@|
// |@@|    |@@|   \@@\/@@/  |@@/      \@@| |@@|\@@\    /@@/|@@|
// |@@@@@@@@@/     \@@@@/   |@@|      |@@| |@@| \@@\  /@@/ |@@|
// |@@@@@@@@@\     /@@/     |@@|      |@@| |@@|  \@@\/@@/  |@@|
// |@@|    |@@|   /@@/      |@@\      /@@| |@@|   \@@@@/   |@@|
// |@@@@@@@@@@|  /@@/        \@@@@@@@@@@@/ |@@|    \@@/    |@@|
// |@@@@@@@@@/  /@@/          \@@@@@@@@@/  |@@|     \/     |@@|

/// +imports
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.0. Contracts (12) + Interfaces (0) + Librairies (2) @@@@@@@@@@@@@@@@@@ */
// from Pre-built ERC20 contracts

import {TokenERC20} from "node_modules/@thirdweb-dev/contracts/token/TokenERC20.sol";

// import {Royalty} from "@thirdweb-dev/contracts/extension/Royalty.sol";

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

contract BYOMbyom is TokenERC20 /* , Royalty */ {
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

    // @Dev: using a Library; getPrice() internal, getConversionRate(uint256 ethAmount) internal

    /// +immutables and constantes
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.2.IMMUTABLES / CONSTANTES  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; // cbdc later on
    //    uint256 public constant UNIT_MULTIPLIER;  (not used yet)

    // Declaring constants for metadata
    address private constant OWNER = 0x106150578098F4Ac8AD8b0f6f806658D4F2eDeD7;
    string private constant NAME = "BYOM France";
    string private constant AUTHOR_URL = "http://www.byom.fr";
    string private constant VERSION = "0.0.1";
    uint64 private constant TIMESTAMP = 3479831479814;
    string private constant CONTRACT_URL = "http://www.byom.fr";

    ModuleMetadata public META_DATA;

    // Custom roles creation
    bytes32 internal constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
    bytes32 internal constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");
    bytes32 internal constant PoS_ROLE = keccak256("PoS_ROLE");
    bytes32 internal constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 internal constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    bytes32 internal constant AMBASSADOR_ROLE = keccak256("AMBASSADOR_ROLE");
    bytes32 internal constant SANCTIONER_ROLE = keccak256("SANCTIONER_ROLE");
    bytes32 internal constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant SUPPORT_ROLE = keccak256("SUPPORT_ROLE");
    bytes32 internal constant POR_ROLE = keccak256("POR_ROLE"); // Proof of Reserve

    /// +variables
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.3. STATE VARIABLES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    bool private initialized; // Flag to track contract initialization
    bool private PlatformFeeInitialized;

    // metatdata variable (see above struct definition)
    // ModuleMetadata private metadata;

    /* subnet's actor types: Abstract account / abstract wallet / accountFactory which handlles the user login
     Should we be using the RoleMembers struct defined in PermissionEnumerable to define these roles + overriding a function?
    */
    // subnet contract owner; not the i_owner. But the first who initializes the contract
    address public subnetOwner;
    // others profiles
    address public subnetAdmin;
    address public subnetSupport;
    address public subnetAuthority;
    address public subnetSanctionRef;
    address public subnetAuditor;
    address public subnetPoR;
    address public subnetClient;
    address public subnetAgent;
    address public subnetMerchant;
    address public subnetAmbassador;
    address public subnetPoS;

    // EVMTarget: the target EVM for this subnet. eg. Avalanche, Ethereum, Binance Smart Chain, Polygon, etc.
    string public subnetEVM;

    // native subnet currency for compliant DeFi
    uint256 public subnetID;
    uint256 public subnetCurrencyDecimals;
    uint256 public subnetCurrencyPeg;
    uint256 public subnetCurrencyPegRate;
    uint256 public subnetinitialSupply;
    // list to storing which address deposited an amount of cbdc
    address[] public subnetDepositors;
    // dictionary
    mapping(address => uint256) public addressToAmount;
    // mapping to retrieve a balance for a specific address
    mapping(address => uint256) balances;
    // Approval granted to transfer tokens from one address to another.
    mapping(address => mapping(address => uint256)) internal allowed; // how do I use this?

    /// +errors
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.4. E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // following errors provide information about why an operation failed.
    error AlreadyInitialized();
    error NotOwner();
    error Unauthorized();
    error ZeroAddress();
    error SameAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error MiniAmountNotOk();

    /// +events    (usage: emit eventName();)
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.5. E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

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
    event withdrawalComplet(address _from, uint256 _amount);

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

    /*
    modifier minimumRequire() {
        if (msg.value.getConversionRate() < MINIMUM_USD)
            revert MiniAmountNotOk();
        _;
    }
    */
    // following modifier exists in Ownable.sol
    modifier onlyOwner() {
        if (msg.sender != subnetOwner) {
            revert NotOwner();
        }
        _;
    }

    /// +functions
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.7. CONSTRUCTOR @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    // no construtor() as this contract is deployed behind a proxy from Thirdweb plateform

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F1: INITx -> TOKEN VARIABLES (ASSET VALUE TRACKING:) INITIAL STATE  <<<<<<<<<<<<< */
    function initialize(
        address _defaultAdmin
    ) external initializer canInitialize(_defaultAdmin) {
        // init to assign immutable variable
        META_DATA = ModuleMetadata(
            NAME,
            Author(OWNER, AUTHOR_URL),
            VERSION,
            TIMESTAMP,
            CONTRACT_URL
        );

        // setting up custom roles for subnet's abstract accounts.
        // the default admin role is from PermissionEnumerable which provides role-based access control.
        _setupRole(DEFAULT_ADMIN_ROLE, subnetOwner);
        _setupRole(ADMIN_ROLE, subnetAdmin);
        _setupRole(CLIENT_ROLE, subnetClient);
        _setupRole(MERCHANT_ROLE, subnetMerchant);
        _setupRole(PoS_ROLE, subnetPoS);
        _setupRole(AGENT_ROLE, subnetAgent);
        _setupRole(AMBASSADOR_ROLE, subnetAmbassador);
        _setupRole(AUTHORITY_ROLE, subnetAuthority);
        _setupRole(SANCTIONER_ROLE, subnetSanctionRef);
        _setupRole(AUDITOR_ROLE, subnetAuditor);
        _setupRole(POR_ROLE, subnetPoR);
        _setupRole(SUPPORT_ROLE, subnetSupport);

        // intit TokenERC20
        TokenERC20(_defaultAdmin);
    }

    // Function to use the `ContractMetadata` extension.
    /**
     * This function returns who is authorized to set the metadata for this contract.
     */
    function _canSetContractURI() internal view virtual returns (bool) {
        return msg.sender == subnetOwner;
    }

    function contractType()
        external
        pure
        override
        returns (bytes32 MODULE_TYPE)
    {
        return (MODULE_TYPE);
    }

    /**
     *  This function returns who is authorized to set royalty info for the chain.
     *  As an EXAMPLE, we'll only allow the subnetOwner to set the royalty info.
     *  We MUST complete the body of this function to use the `Royalty` extension.
     
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return msg.sender == subnetOwner;
    }
    */
}
