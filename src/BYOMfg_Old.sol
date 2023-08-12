// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/// +imports
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.0. IMPORTS (10) @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
// from Pre-built ERC20 contracts/ token
import {TokenERC20} from "@thirdweb-dev/contracts/token/TokenERC20.sol";
// the smart contract's metadata from an extension contract.
import {ContractMetadataPlus} from "@thirdweb-dev/contracts/extension/ContractMetadataPlus.sol";
// ownership of any instance of this contract (initializer)
import {Ownable} from "@thirdweb-dev/contracts/extension/Ownable.sol";
import {PermissionsEnumerable} from "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import {PlatformFee} from "@thirdweb-dev/contracts/extension/PlatformFee.sol";
import {PrimarySale} from "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import {Staking20Base} from "@thirdweb-dev/contracts/base/Staking20Base.sol";
// connecting to real world currency price with chainlink
import {AggregatorV3Interface} from "./utils/AggregatorV3Interface.sol";
// Get the latest ETH/USD price from chainlink price feed
//  interface at https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import {PriceConverter} from "./utils/PriceConverter.sol"; // getPrice() internal, getConversionRate(uint256 ethAmount)  internal
import {SafeMath} from "./utils/SafeMath.sol";

/// +inheritance
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.0. BASE CONTRACT, EXTENSIONS & LIBRARIES @@@@@@@@@@@@@@@@@@@@@ */
contract BYOMfg is
    TokenERC20,
    ContractMetadataPlus,
    Ownable,
    PermissionsEnumerable,
    PlatformFee,
    Staking20Base,
    PriceConverter,
    SafeMath,
    AggregatorV3Interface
{
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.1.  CUSTOM TYPES  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    using PriceConverter for uint256; //using a Library;

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.2. IMMUTABLE & CONSTANT VARIABLES DEFINITION  @@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // @Dev: Chain owner address is "private", so only visible to the chain owner (instant of the smart contract)
    address private immutable i_owner; // Owner of this contract (not instance of the contract)
    bool private _initialized; // Flag to track contract initialization

    // Any `bytes32` value is a valid role. You can create roles by defining them like this.
    // bytes32 public constant NUMBER_ROLE = keccak256("NUMBER_ROLE");
    bytes32 public constant CUSTOMER = keccak256("CUSTOMER");
    bytes32 public constant PoS = keccak256("PoS");
    bytes32 public constant MERCHANT = keccak256("MERCHANT");
    bytes32 public constant AMBASSADOR = keccak256("AMBASSADOR");
    bytes32 public constant AUDITOR = keccak256("AUDITOR");
    bytes32 public constant AUTHORITY = keccak256("AUTHORITY");
    bytes32 public constant SANCTIONREF = keccak256("SANCTIONREF");
    bytes32 public constant PoR = keccak256("PoR");
    bytes32 public constant SUPPORT = keccak256("SUPPORT");
    bytes32 public constant BUSINESSADMIN = keccak256("BUSINESSADMIN");
    // chain management
    address private chainOwner; // Owner of an instance of this contract.
    uint256 public chainID;
    // chain currency
    uint256 public chainCurrencyPeg;
    uint256 public chainCurrencyPegRate;
    uint256 public chainCurrencyDecimal;
    uint256 public chainInitialSupply; // Tokens created when contract was deployed
    uint256 public chainTotalSupply; // Tokens currently in circulation (VarCap or FixedCap?)
    string public chainCurrencyName;
    string public chaiCurrencynSymbol;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    uint256 public constant UNIT_MULTIPLIER = 10 ** uint256(decimals);

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.3. STATE VARIABLES DEFINITION  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> LIST  <<<<<<<<<<<<<<<<<<<<<<<<<*/
    address[] public chainDepositors;

    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAPPINGS (DICTIONARY) <<<<<<<<<<<<<<<<<<<<<<<<<*/
    //mapping to store which address deposited an amount of ETH
    mapping(address => uint256) public addressToAmount; // dictionary
    //mapping to retrieve a balance for a specific address
    mapping(address => uint256) balances;
    // Approval granted to transfer tokens from one address to another.
    mapping(address => mapping(address => uint256)) internal allowed;

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.4. E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    ///+events                          // emit eventName();
    event DepositRecieved(address _to, uint256 _amount);
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
    event TransferComplet(address _to, uint256 _amount);
    event withdrawalComplet(address _from, uint256 _amount);

    /// +errors
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.5. E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // Errors allow you to provide information about why an operation failed.
    error NotOwner();
    error NotChainAdmin();
    error NotChainAuthority();
    error NotChainSanctionRef();
    error NotChainPoR();
    error NotChainAgent();
    error NotChainMerchant();
    error NotChainPoS();
    error Unauthorized();
    error AlreadyInitialized();
    error ZeroAddress();
    error SameAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error MiniAmountNotOk();
    error NotCompliant();
    error KycNotCompliant();
    error amlNotCompliant();
    error cftNotCompliant();
    error AgentMaxPerDayExceeded();
    error AgentMaxPerWeekExceeded();
    error AgentMaxPerMonthExceeded();
    error AgentMaxPerYearExceeded();
    error CustomerMaxPerDayExceeded();
    error CustomerMaxPerWeekExceeded();
    error CustomerMaxPerMonthExceeded();
    error CustomerMaxPerYearExceeded();
    error MerchantMaxPerDayExceeded();
    error MerchanMaxPerWeekExceeded();
    error MerchanMaxPerMonthExceeded();
    error MerchanMaxPerYearExceeded();
    error PosMaxPerDayExceeded();
    error PosMaxPerWeekExceeded();
    error PosMaxPerMonthExceeded();
    error PosMaxPerYearExceeded();

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.6.  M O D I F I E R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    ///+modifiers

    modifier canInitialize(address chainOwner) {
        if (!initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
    modifier isChainAdmin() {
        if (msg.sender != _chainAdmin) {
            revert NotchainAdmin();
        }
        _;
    }
    modifier isChainCustomer() {
        if (msg.sender != _chainCustomer) {
            revert Unauthorized();
        }
        _;
    }
    modifier isChainMerchant() {
        if (msg.sender != _chainMerchant) {
            revert MerchantOnly();
        }
        _;
    }
    modifier isChainPoS() {
        if (msg.sender != _chainPoS) {
            revert PoSOnly();
        }
        _;
    }
    modifier isChainAgent() {
        if (msg.sender != _chainAgent) {
            revert AgentOnly();
        }
        _;
    }
    modifier isChainAuthority() {
        if (msg.sender != _chainAuthority) {
            revert ChainAuthorityOnly();
        }
        _;
    }
    modifier isChainSanctionRef() {
        if (msg.sender != _chainSanctionRef) {
            revert ChainSanctionRefOnly();
        }
        _;
    }
    modifier isChainPoR() {
        if (msg.sender != _chainPoR) {
            revert ChainPoROnly();
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
    modifier minimumRequire() {
        if (msg.value.getConversionRate() < MINIMUM_USD)
            revert MiniAmountNotOk();
        _;
    }

    /*
        modifier onlyKyced() {
            //is the message sender owner of the contract?
            require(msg.sender == kyced);
            _;
        }
        modifier onlyNotSanctioned() {
            //is the message sender owner of the contract?
            require(msg.sender == notSanctioned);
            _;
        }
    */

    /* The following constructor sets up the TokenERC20 contract, stores the contract's owner
     *  and initializes metadata for this contract.
     */
    constructor(
        // Calling the constructor of the Parent Contract:
        address _defaultAdmin,
        string memory _name, // default_Curency_name, eg. USD
        string memory _symbol, // default_Currency_symbol
        address _primarySaleRecipient
    ) TokenERC20(_defaultAdmin, _name, _symbol, _primarySaleRecipient) {
        // Owner Assignment:
        i_owner = msg.sender;
        console.log("Owner is deploying the BYOM contract", "${i_owner}");

        /// 1. Extending with "ContractMetadataPlus " abstract contract
        // The metadata variable is being populated with values using the ContractMetadataPlus structure, define in IContractMetadataPlus
        metadata = ContractMetadataPlus(
            "BYOM France",
            Author(i_owner, "https://externallink.net"),
            "0.0.1",
            3479831479814,
            "https://externalLink.net"
        );

        _initialized = false; // Contract is not yet initialized
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F1: INITx -> TOKEN VARIABLES (ASSET VALUE TRACKING:) INITIAL STATE  <<<<<<<<<<<<< */
    /* dev Since proxied contracts do not make use of a constructor, 
     * we move constructor logic to an external initializer function called `initialize`

     * @dev Initializes a contract by setting chain parameters.
     * @dev Initializes an instance of a chain for this contract and sets the state variables.
     * @dev initializer is a parent from "import "./utils/Initializable.sol""?
     * @dev unique time we get in, these parameters are set,
     * @dev Then next time, execution will be forbiden by canInitialize modifier.
     */

    /**
     * @notice Initializes the contract and sets the owner.
     * @param _newOwner The address to set as the new owner of the contract.
     */

    function initialize(
        _newOwner,
        _chainID,
        _chainCurrencyName,
        _chaiCurrencynSymbol,
        _chainCurrencyDecimal,
        _chainCurrencyPeg,
        _chainCurrencyPegRate,
        _chainInitialSupply,
        _chainTotalSupply
    ) external initializer canInitialize(_newOwner) {
        /// 2. Extending with "Ownable" abstract contract
        _setupOwner(_newOwner);
        _initialized = true;

        /// 3. Extending with "PermissionEnumerable" abstract contract
        /* lets create roles.
         * The Enumerable part provides the capability to view all the addresses holding a specific role.
         */
        // setting Chain roles.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // inherited from PermissionEnumerable which provides role-based access control.
        _setupRole(_CUSTOMER_ROLE, CUSTOMER);
        _setupRole(_PoS_ROLE, PoS);
        _setupRole(_MERCHANT_ROLE, MERCHANT);
        _setupRole(_AMBASSADOR_ROLE, AMBASSADOR);
        _setupRole(_AUDITOR_ROLE, AUDITOR);
        _setupRole(_AUTHORITY_ROLE, AUTHORITY);
        _setupRole(_SANCTIONREF_ROLE, SANCTIONREF);
        _setupRole(_PoR_ROLE, PoR);
        _setupRole(_SUPPORT_ROLE, SUPPORT);
        _setupRole(_BUSINESSADMIN_ROLE, BUSINESSADMIN);

        // setting Chain parameters
        chainID = _chainID;
        chainCurrencyName = _chainCurrencyName;
        chaiCurrencynSymbol = _chaiCurrencynSymbol;
        chainCurrencyDecimal = _chainCurrencyDecimal;
        chainCurrencyPeg = _chainCurrencyPeg;
        chainCurrencyPegRate = _chainCurrencyPegRate;
        chainInitialSupply = _chainInitialSupply;
        chainTotalSupply = _chainTotalSupply;

        // all the total supply is credited to the owner
        balances[chainOwner] = chainTotalSupply;

        // @dev Emitted when a new Owner is set.
        emit Initialized(chainOwner, _chainID);
    }

    // Override _canSetOwner to control who can set the owner during initialization
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner(); // when "true", allow owner to set during initialization
    }

    /// 4. Extending with "PlatformFee" abstract contract

    /// 5. Extending with "Staking20Base" abstract contract

    /// 6. Extending with "PrimarySale" abstract contract

    /// @Dev: having created roles, we need to write custom logic that depends on whether a given wallet holds a given role.

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> get the version of the chainlink pricefeed (public view) <<<<<<<<<<<<< */
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> get the price from thee chainlink pricefeed (public view) <<<<<<<<<<<<< */
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> get conversion rate USD/ETH (public view) <<<<<<<<<<<<< */
    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> DEPOSIT (public payable) <<<<<<<<<<<<< */
    /* @dev  Allow the user to deposit */
    function deposit() public payable minimumRequire {
        // @Dev: payable function which needs to add minimum ETH
        // 18 digit number to be compared with deposited amount
        uint256 minimumUSD = 5 * 10 ** 18; //the deposited amount is not less than 5 USD?
        addressToAmount[msg.sender] += msg.value;
        chainDepositors.push(msg.sender);
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> WITHDRAW-ALL (public payable) <<<<<<<<<<<<< */
    // @Dev: payable function to withdraw all the ETH from the contract, by the owner only
    function ownerWithdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        //iterate through the depositors list and make them 0 since all the deposited amount has been withdrawn
        for (
            uint256 chainDepositorIndex = 0;
            chainDepositorIndex < chainDepositors.length;
            chainDepositorIndex++
        ) {
            address chainDepositors = chainDepositors[chainDepositorIndex];
            addressToAmount[chainDepositors] = 0;
        }
        // chainDepositors list will be reset to 0
        chainDepositors = new address[](0);
    }

    /*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ H E L P E R  F U N C T I O N S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
    // special functions such as constructor(), fallback() and receive() don't need the keyword function.

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F16 -> FALLBACK() and RECIEVE() (external payable) <<<<<<<<<<<<< */
    fallback() external payable {
        // as constructor, fallback() a special Solidity function
        deposit();
    }

    receive() external payable {
        // recieve() is  a special Solidity function too
        deposit();
    }
}
