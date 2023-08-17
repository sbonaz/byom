// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/// +imports
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.0. Contracts + Interfaces + Librairies (9) @@@@@@@@@@@@@@@@@@ */
// from Pre-built ERC20 contracts

import {TokenERC20} from "@thirdweb-dev/contracts/token/TokenERC20.sol";
// the smart contract's metadata from an extension contract.
import {ContractMetadataPlus} from "@thirdweb-dev/contracts/extension/ContractMetadataPlus.sol";
// ownership of any instance of this contract (initializer)
import {Ownable} from "@thirdweb-dev/contracts/extension/Ownable.sol";
import {PermissionsEnumerable} from "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import {PlatformFee} from "@thirdweb-dev/contracts/extension/PlatformFee.sol";
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
    Staking20,
    PriceConverter,
    SafeMath,
    AggregatorV3Interface
{
    /// +types
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.1. CUSTOM TYPES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // @Dev: using a Library; getPrice() internal, getConversionRate(uint256 ethAmount) internal

    using PriceConverter for uint256;

    /// +immutables and constantes
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.2.IMMUTABLES / CONSTANTES  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // @Dev: owner address is "private", so only visible to this contract owner.

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    uint256 public constant UNIT_MULTIPLIER = 10 ** uint256(decimals);
    // Any `bytes32` value is a valid role.
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

    /// +variables
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.3. STATE VARIABLES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    bool private _initialized; // Flag to track contract initialization
    address private chainOwner; // Owner of an instance of this contract.
    uint256 public chainID;
    uint256 public chainCurrencyPeg;
    uint256 public chainCurrencyPegRate;
    uint256 public chainCurrencyDecimal;
    uint256 public chainTotalSupply; // Tokens currently in circulation (VarCap or FixedCap?)
    string public chainCurrencyName;
    string public chainCurrencySymbol;

    // mapping to store which address deposited an amount of ETH
    address[] public chainDepositors;
    // dictionary
    mapping(address => uint256) public addressToAmount;
    // mapping to retrieve a balance for a specific address
    mapping(address => uint256) balances;
    // Approval granted to transfer tokens from one address to another.
    mapping(address => mapping(address => uint256)) internal allowed;

    /// +errors
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.4. E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // Errors allow you to provide information about why an operation failed.

    error NotOwner();
    error Unauthorized();
    error AlreadyInitialized();
    error ZeroAddress();
    error SameAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error MiniAmountNotOk();
    error NotchainOwner();
    error NotChainAdmin();
    error NotChainAuthority();
    error NotChainSanctionRef();
    error NotChainPoR();
    error NotChainAgent();
    error NotChainMerchant();
    error NotChainPoS();
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

    /// +events    (emit eventName();)
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

    modifier canInitialize(address chainOwner) {
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
    modifier minimumRequire() {
        if (msg.value.getConversionRate() < MINIMUM_USD)
            revert MiniAmountNotOk();
        _;
    }
    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert NotOwner();
        }
        _;
    }
    modifier onlychainOwner() {
        if (msg.sender != chainOwner) {
            revert NotchainOwner();
        }
        _;
    }
    modifier isChainAdmin() {
        if (msg.sender != _chainAdmin) {
            revert NotchainAdmin();
        }
        _;
    }
    modifier isChainAuthority() {
        if (msg.sender != _chainAuthority) {
            revert NotchainAuthority();
        }
        _;
    }
    modifier isChainSanctionRef() {
        if (msg.sender != _chainSanctionRef) {
            revert NotchainSanctionRef();
        }
        _;
    }
    modifier isChainPoR() {
        if (msg.sender != _chainPoR) {
            revert NotchainPoR();
        }
        _;
    }
    modifier isChainAgent() {
        if (msg.sender != _chainAgent) {
            revert NotchainAgent();
        }
        _;
    }
    modifier isChainMerchant() {
        if (msg.sender != _chainMerchant) {
            revert NotchainMerchant();
        }
        _;
    }
    modifier isChainPoS() {
        if (msg.sender != _chainPoS) {
            revert NotchainPoS();
        }
        _;
    }
    modifier isChainCustomer() {
        if (msg.sender != _chainCustomer) {
            revert Unauthorized();
        }
        _;
    }
    modifier roleXOnly() {
        if (
            msg.sender != _chainOwner &&
            msg.sender != _chainAdmin &&
            msg.sender != _chainAuthority &&
            msg.sender != _chainSanctionRef &&
            msg.sender != _chainPoR &&
            msg.sender != _chainAgent &&
            msg.sender != _chainMerchant &&
            msg.sender != _chainPoS
        ) {
            revert Unauthorized();
        }
        _;
    }
    modifier onlyCompliant() {
        if (
            msg.sender != _chainOwner &&
            msg.sender != _chainAdmin &&
            msg.sender != _chainAuthority &&
            msg.sender != _chainSanctionRef &&
            msg.sender != _chainPoR &&
            msg.sender != _chainAgent &&
            msg.sender != _chainMerchant &&
            msg.sender != _chainPoS &&
            msg.sender != _chainCustomer
        ) {
            revert NotCompliant();
        }
        _;
    }

    /*
    modifier onlyKyced() {
        //is the message sender KYCed?
        require(msg.sender == kyced);
        _;
    }
    modifier onlyNotSanctioned() {
        //is the message sender sanctionfree?
        require(msg.sender == notSanctioned);
        _;
    }
    */

    /// +constructor
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.7. CONSTRUCTOR @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
    // The following constructor sets up owner and metadata for this contract only.
    constructor() {
        // Owner Assignment:
        i_owner = msg.sender;
        console.log("Owner is deploying the BYOM contract", "${i_owner}");

        /// 1. Levraging "ContractMetadataPlus" abstract contract, to set up contract metadatas
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

    /// +functions
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.0. FUNCTIONS @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F1: INITx -> TOKEN VARIABLES (ASSET VALUE TRACKING:) INITIAL STATE  <<<<<<<<<<<<< */

    function initialize(
        address _newOwner,
        uint256 _chainID,
        string memory _chainCurrencyName,
        string memory _chainCurrencySymbol,
        uint256 _chainCurrencyDecimal,
        uint256 _chainCurrencyPeg,
        uint256 _chainCurrencyPegRate,
        uint256 _chainTotalSupply,
        uint256 _platformFeeBps,
        uint256 _flatPlatformFee,
        uint80 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator
    )
        external
        // calling the TokenERC20 constructor.
        TokenERC20(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _primarySaleRecipient,
            _platformFeeRecipient,
            _platformFeeBps
        )
        initializer
        canInitialize(_newOwner)
    {
        /// 2. Levraging "Ownable" abstract contract
        _setupOwner(_newOwner);
        _initialized = true;

        /// 3. Levraging "PermissionEnumerable" abstract contract
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

        // Todo:
        // further features: user status during Tx: Depositor / Delegator, Holder (Self Custodial), Spender,/ Withdrawer.
        // we will incetivize the Delegator power by rewarding duration + amount delegated (less Spender or Holder).

        // setting Chain parameters
        chainID = _chainID;
        chainCurrencyName = _chainCurrencyName;
        chaiCurrencySymbol = _chaiCurrencySymbol;
        chainCurrencyDecimal = _chainCurrencyDecimal;
        chainCurrencyPeg = _chainCurrencyPeg;
        chainCurrencyPegRate = _chainCurrencyPegRate;
        chainTotalSupply = _chainTotalSupply;

        /// 4. Levraging "PlatformFee" abstract contract
        // Set platform fee details
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupFlatPlatformFeeInfo(_platformFeeRecipient, _flatPlatformFee);

        /// 5. Levraging "Staking20" abstract contract: Initialize Staking Conditions:
        _setStakingCondition(
            _timeUnit,
            _rewardRatioNumerator,
            _rewardRatioDenominator
        );

        // all the total supply is credited to the owner
        balances[chainOwner] = chainTotalSupply;

        // @dev Emitted when a new Owner is set.
        emit Initialized(chainOwner, _chainID);
        // Emit event for platform fee setup
        emit PlatformFeeInitialized(
            _platformFeeRecipient,
            _platformFeeBps,
            _flatPlatformFee
        );
    }

    // Override _canSetOwner() to control who can set the owner during initialization
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner(); // when "true", allow owner to set during initialization
    }

    // Access Platform Fee Information:
    function getPlatformFee()
        public
        view
        returns (address, uint16, PlatformFeeType)
    {
        (address feeRecipient, uint16 feeBps) = getPlatformFeeInfo();
        PlatformFeeType feeType = getPlatformFeeType();
        return (feeRecipient, feeBps, feeType);
    }

    /// Levraging Staking features:

    // Overriding the function -stake() to implement internal Staking Logic:

    // Overriding the _withdraw() function to handle the withdrawal of staked tokens

    // Overriding the _calculateRewards() function to calculate rewards for stakers

    // Overriding the _mintRewards() function to mint and transfer rewards to stakers.

    /* Overriding the _canSetStakeConditions() function to control who can modify the staking conditions.
     * This function should return true if the caller is authorized to set stake conditions.
     */

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
    /* @dev  Allow the user to deposit USD */

    function deposit() public payable minimumRequire {
        // @Dev: payable function which needs to add minimum ETH
        // 18 digit number to be compared with deposited amount
        uint256 minimumUSD = 50 * 10 ** 18; // the deposited amount is not less than 50 USD?
        addressToAmount[msg.sender] += msg.value;
        chainDepositors.push(msg.sender);

        /* Todo: fund sent directly to PoR (AVAX delegation to BYOMfg's validators, base by uptime, for minimum of 2 weeks?!)
         * rewards will come to pay the supervalidator in charge of borrowing when user transfer its hold
         * With the 'signature minting' mechanism: the user generate a 'mint request' to the contract, which will be signed  by the contract's Admin.
         * The contract's Admin will then send back the signed payload, of mint request, to the the depositor, autorizing the depositor to mint the requested amount of tokens.
         *
         */
    }

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> TRANSFER (public) <<<<<<<<<<<<< */
    /* Overriding transfer()/ send() / transferTo()/ transferFrom() from Token20 by adding logic to:
     * 1) flashloan to cash-advanced sender,
     * 2)  by claiming ownership of the amount borrowed on behalf of the sender, to get back fund from PoR.
     */

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> WITHDRAW-ALL (public payable) <<<<<<<<<<<<< */
    // @Dev: payable function to withdraw all the ETH from the contract, by the contract owner only
    function chainOwnerWithdraw() public payable onlychainOwner {
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

    /* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> F -> WITHDRAW-ROLEX (public payable) <<<<<<<<<<<<< */
    // Overriding withraw function fron Token20 base contract.
    function roleXWithdraw() public payable roleXOnly {}

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ H E L P E R  F U N C T I O N S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
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
