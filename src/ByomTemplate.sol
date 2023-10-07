// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* Caution: 
    Importing TokenERC20 in this contract does not provide direct access to the functions from these contracts. 
    It's a one-way relationship in terms of visibility and accessibility.
    In order to use any function from these contracts, we would need to create wrapper functions. 
    However, we would need the address of each above contract (for instance: _contractMetadataAddress) to interact with those functions. 
    The address is typically known after deployment.
*/

import {TokenERC20} from "node_modules/@Thirdweb-dev/contracts/prebuilts/token/TokenERC20.sol";

/*
    TokenERC20Address : 0x04cdaaDCcb15214357fa65547E32BbEE3017988c and
    TokenERC20FactoryAddress: 0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0, on Fuji
    */

contract ByomTemplate is TokenERC20 {
    /// +types
    /*///////////////////////////////////////////////////////////////
                                0.1. CUSTOM TYPES
    //////////////////////////////////////////////////////////////*/

    // Custom types definition for specific ByomMetadata
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
    // a Tuple Req
    struct Req {
        address to;
        address primarySaleRecipient;
        uint8 quantity;
        uint64 price;
        address currency;
        uint64 validityStartTimestamp;
        uint64 validityEndTimestamp;
        uint64 uid;
    }

    /// +immutables and constantes
    /*///////////////////////////////////////////////////////////////
                                0.2.IMMUTABLES / CONSTANTES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; // cbdc later on
    // Declaring constants for ByomMetadata
    address private immutable i_owner;
    string private constant NAME = "BYOM France";
    string private constant AUTHOR_URL = "http://www.byom.fr";
    string private constant VERSION = "0.0.1";
    uint64 private constant TIMESTAMP = 3479831479814;
    string private constant CONTRACT_URL = "http://www.byom.fr";
    ModuleMetadata public META_DATA;
    // ROLES list (leveraging : Abstract account / abstract wallet / accountFactory which handlles the user login)
    enum Role {
        GUEST_ROLE, // #0
        // GUEST's function: , Explor_Tx
        CLIENT_ROLE, // #1
        // client's functions: Subscribe_to_SC, Cashin, Transfer, Merchant_Payment, Explor_Tx, Cashout
        MERCHANT_ROLE, // #2
        // Merchant's functions: Subscribe_to_SC, Whole_sale_Cashin, TransferFrom, Receiveve_Payment, Explor_Tx, Cashout
        PoS_ROLE, // #3
        // XXX's functions: Subscribe_to_SC, Cashin, Transfer, Merchant_Payment, Explor_Tx, Cashout
        AGEANT_ROLE, // #4
        // XXX's functions: Subscribe_to_SC, Cashin, Transfer, Merchant_Payment, Explor_Tx, Cashout
        AMBASSADOR_ROLE, // #5
        // XXX's functions: Subscribe_to_SC, Cashin, Transfer, Merchant_Payment, Explor_Tx, Cashout
        SUPPORT_ROLE, // #6
        PoAR_ROLE, // #7  Proof Of Assets & Reserves. We can have multiple addresses with this role. Each address for specific crypto.
        ORAMP_ROLE, // #8
        ADMIN_ROLE, // #9
        AUDITOR_ROLE, // #10
        AUTHORITY_ROLE, // #11
        SANCTIONER_ROLE // #12

        /*     Primary roles set up in TokenERC20 contract 
                    DEFAULT_ADMIN_ROLE, #13
                    TRANSFER_ROLE,      #14
                    MINTER_ROLE,        #15
                    TRANSFER_ROLE,      #16
            */
        /* PoA&R: Proof of Assets and Reserves are a 3rd party smart contract that protocols can use to monitor the BYOM's asset collateral 
                    and to prove that is stable and accurate. It is an additional on-chain verification to provide confidence to BYOM users and to protocols
                    that support Byom tokens.
                   */
    }

    /// +variables
    /*///////////////////////////////////////////////////////////////
                                0.3. GLOBAL STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address _defaultAdmin; // will be sent for initializing TokenERC20
    Role public roleAssigned;
    // Native currency in compliant DeFi
    uint256 public nativeCurrencyDecimals;
    uint256 public nativeCurrencyPeg0;
    uint256 public nativeCurrencyPeg1;
    uint256 public nativeCurrencyPeg2;
    uint256 public nativeCurrencyPeg3;
    uint256 public nativeCurrencyPeg4;
    uint256 public nativeCurrencyPeg5;
    uint256 public nativeCurrencyPegRate0;
    uint256 public nativeCurrencyPegRate1;
    uint256 public nativeCurrencyPegRate3;
    uint256 public nativeCurrencyPegRate4;
    uint256 public nativeCurrencyPegRate5;
    // Dictionary
    mapping(Role => bytes32) public roleToBytes32; // ie. CLIENT_ROLE  -> keccack256("CLIENT_ROLE") : memorized role in the blockchain
    mapping(address => bytes32) public addressToRoleHash; // ie. 0x04cdaaDCcb15214357fa65547E32BbEE3017988c -> keccack256("CLIENT_ROLE")
    // List of role hashes
    bytes32[] public roleHashes;

    /// +errors
    /*///////////////////////////////////////////////////////////////
                                0.4. E R R O R S
    //////////////////////////////////////////////////////////////*/

    // following errors provide information about why an operation failed.
    error AlreadyInitialized();
    error NotOwner();
    error NotSubnetAdmin();
    error Unauthorized();
    error ZeroAddress();
    error ZeroAccount();
    error SameAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error MiniAmountNotOk();
    error NotCompliant();
    error Address_Sanctioned();

    /// +modifiers
    /*///////////////////////////////////////////////////////////////
                                0.5.  M O D I F I E R S
    //////////////////////////////////////////////////////////////*/

    // Modifier to allow only specific roles to execute certain functions
    modifier OnlyAllowedRoles() {
        require(
            hasRole(roleToBytes32[Role.CLIENT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.MERCHANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.PoS_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AGEANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AMBASSADOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SUPPORT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.PoAR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.ORAMP_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.ADMIN_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUDITOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUTHORITY_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SANCTIONER_ROLE], msg.sender),
            "Caller does not have the required role for this transaction"
        );
        _;
    }
    // Modifier to allow only specific roles to execute certain functions
    modifier notAllowedRole() {
        require(
            !(hasRole(roleToBytes32[Role.CLIENT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.MERCHANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.PoS_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AGEANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AMBASSADOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SUPPORT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.PoAR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.ADMIN_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUDITOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUTHORITY_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.ORAMP_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SANCTIONER_ROLE], msg.sender)),
            "Caller is already known"
        );
        _;
    }
    // Enforcing the role-based access control.
    modifier onlyClientRole() {
        require(
            hasRole(roleToBytes32[Role.CLIENT_ROLE], msg.sender),
            "Caller does not have the CLIENT role for this transaction"
        );
        _;
    }
    modifier onlyMerchantRole() {
        require(
            hasRole(roleToBytes32[Role.MERCHANT_ROLE], msg.sender),
            "Caller does not have the MERCHANT role"
        );
        _;
    }
    modifier onlyPoSRole() {
        require(
            hasRole(roleToBytes32[Role.PoS_ROLE], msg.sender),
            "Caller does not have the Point_Of_Sale role"
        );
        _;
    }
    modifier onlyAgeantRole() {
        require(
            hasRole(roleToBytes32[Role.AGEANT_ROLE], msg.sender),
            "Caller does not have the AGEANT role"
        );
        _;
    }
    modifier onlyAmbassadorRole() {
        require(
            hasRole(roleToBytes32[Role.AMBASSADOR_ROLE], msg.sender),
            "Caller does not have the AMBASSADOR role"
        );
        _;
    }
    modifier onlySupportRole() {
        require(
            hasRole(roleToBytes32[Role.SUPPORT_ROLE], msg.sender),
            "Caller does not have the SUPPORT role"
        );
        _;
    }
    modifier onlyPORRole() {
        require(
            hasRole(roleToBytes32[Role.PoAR_ROLE], msg.sender),
            "Caller does not have the PoAR role"
        );
        _;
    }
    modifier onlyDEFAULT_ADMIN_ROLE() {
        require(
            hasRole(bytes32(DEFAULT_ADMIN_ROLE), msg.sender),
            "Caller does not have the ADMIN role"
        );
        _;
    }
    modifier onlyAdminRole() {
        require(
            hasRole(roleToBytes32[Role.ADMIN_ROLE], msg.sender),
            "Caller does not have the ADMIN role"
        );
        _;
    }
    modifier onlyAuditorRole() {
        require(
            hasRole(roleToBytes32[Role.AUDITOR_ROLE], msg.sender),
            "Caller does not have the AUDITOR_ROLE role"
        );
        _;
    }
    modifier onlyAthorityRole() {
        require(
            hasRole(roleToBytes32[Role.AUTHORITY_ROLE], msg.sender),
            "Caller does not have the AUTHORITY role"
        );
        _;
    }
    modifier onlySanctionerRole() {
        require(
            hasRole(roleToBytes32[Role.SANCTIONER_ROLE], msg.sender),
            "Caller does not have the SANCTIONER role"
        );
        _;
    }
    modifier onlyOn_RAMP_ROLE() {
        require(
            hasRole(roleToBytes32[Role.ORAMP_ROLE], msg.sender),
            "Caller does not have the ON_RAMP_ROLE"
        );
        _;
    }
    modifier OnlyTRANSFER_ROLE() {
        require(
            hasRole(keccak256("TRANSFER_ROLE"), msg.sender),
            "Caller does not have the TRANSFER_ROLE"
        );
        _;
    }
    modifier OnlyMINTER_ROLE() {
        require(
            hasRole(keccak256("MINTER_ROLE"), msg.sender),
            "Caller does not have the MINTER_ROLE"
        );
        _;
    }
    /*
    modifier canInitialize(address i_owner) {
        if (!initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
    */
    // Address check
    modifier AddressCheck(address _from, address _to) {
        if (_from == _to) {
            revert SameAddress();
        }
        if (_to == address(0) || _from == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
    // Not zero account
    modifier NotZeroAccount(address _account, Role _accountRole) {
        if (_account == address(0) || _accountRole == Role(0)) {
            revert ZeroAccount();
        }
        _;
    }
    // Compliance check
    modifier ComplianceCheck(
        address _from,
        address _to,
        bool kycStatus,
        bool amlStatus,
        bool cftStatus, //  bool sanctionStatus
        uint256 amount
    ) {
        if (
            kyc(_to, kycStatus) == false ||
            kyc(_from, kycStatus) == false ||
            aml(_to, amlStatus) == false ||
            aml(_from, amlStatus) == false ||
            cft(_to, cftStatus) == false ||
            cft(_from, cftStatus) == false
        ) {
            revert NotCompliant();
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
    /*
    modifier minimumRequire() {
        if (msg.value.getConversionRate() < MINIMUM_USD)
            revert MiniAmountNotOk();
        _;
    }
    */

    /// +events    (usage: emit eventName();)
    /*///////////////////////////////////////////////////////////////
                                0.6. E V E N T S
    //////////////////////////////////////////////////////////////*/

    event NewGuestCreated(address account);
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

    /*///////////////////////////////////////////////////////////////
                                1.1. CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // The construtor is useless if this contract is deployed through a proxy, on Thirdweb plateform for instance.

    constructor() {
        META_DATA = ModuleMetadata(
            NAME,
            Author(i_owner, AUTHOR_URL),
            VERSION,
            TIMESTAMP,
            CONTRACT_URL
        );
        i_owner = msg.sender;
        // init to assign this contract specific immutable variables
        _defaultAdmin = i_owner;
        // Initialize role hashes array
        roleHashes = [
            keccak256("GUEST_ROLE"), // 0
            keccak256("CLIENT_ROLE"), // 1
            keccak256("MERCHANT_ROLE"), // 2
            keccak256("PoS_ROLE"), // 3
            keccak256("AGEANT_ROLE"), // 4
            keccak256("AMBASSADOR_ROLE"), // 5
            keccak256("SUPPORT_ROLE"), // 6
            keccak256("ADMIN_ROLE"), // 7
            keccak256("PoAR_ROLE"), // 8      Proof of Assets & Reserves
            keccak256("ORAMP_ROLE"), // 9
            keccak256("AUDITOR_ROLE"), // 10
            keccak256("AUTHORITY_ROLE"), // 11
            keccak256("SANCTIONER_ROLE") // 12
        ];
        /*   grantRole(
            0x0000000000000000000000000000000000000000000000000000000000000000, _defaultAdmin); 
        */
        // intit TokenERC20
        TokenERC20(_defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                                1.2. EXTENDED METADATA
    //////////////////////////////////////////////////////////////*/

    // Function to use the `ContractMetadata` extension.
    /**
     * This function returns who is authorized to set the metadata for this contract.
     */
    function _canSetContractURI() internal view virtual returns (bool) {
        return msg.sender == i_owner;
    }

    /*///////////////////////////////////////////////////////////////
                                1.3. CONTRACT'S ADDRESS SETTERS
    //////////////////////////////////////////////////////////////*/

    // Call from constructor()  ?

    // setter function that allows to set the _contractMetadataAddress after deployment.
    function setContractMetadataAddress(
        address contractMetadataAddress
    ) external onlyOwner returns (address _contractMetadataAddress) {
        _contractMetadataAddress = contractMetadataAddress;
    }

    // setter function that allows to set the _ERC20Address after deployment.
    function setERC20Address(
        address ERC20Address
    ) external onlyOwner returns (address _ERC20Address) {
        _ERC20Address = ERC20Address;
    }

    // setter function that allows to set the _ERC20BurnableAddress after deployment.
    function setERC20BurnableAddress(
        address ERC20BurnableAddress
    ) external onlyOwner returns (address _ERC20BurnableAddress) {
        _ERC20BurnableAddress = ERC20BurnableAddress;
    }

    // setter function that allows to set the _ERC20MintableAddress after deployment.
    function setERC20MintableAddress(
        address ERC20MintableAddress
    ) external onlyOwner returns (address _ERC20MintableAddress) {
        _ERC20MintableAddress = ERC20MintableAddress;
    }

    // setter function that allows to set the _ERC20BatchMintableAddress after deployment.
    function setERC20BatchMintableAddress(
        address ERC20BatchMintableAddress
    ) external onlyOwner returns (address _ERC20BatchMintableAddress) {
        _ERC20BatchMintableAddress = ERC20BatchMintableAddress;
    }

    // setter function that allows to set the _ERC20SignatureMintableAddress after deployment.
    function setERC20SignatureMintableAddress(
        address ERC20SignatureMintableAddress
    ) external onlyOwner returns (address _ERC20SignatureMintableAddress) {
        _ERC20SignatureMintableAddress = ERC20SignatureMintableAddress;
    }

    // setter function that allows to set the _ERC20PermitAddress after deployment.
    function setERC20PermitAddress(
        address ERC20PermitAddress
    ) external onlyOwner returns (address _ERC20PermitAddress) {
        _ERC20PermitAddress = ERC20PermitAddress;
    }

    // setter function that allows to set the _PlatformFeeAddress after deployment.
    function setPlatformFeeAddress(
        address PlatformFeeAddress
    ) external onlyOwner returns (address _PlatformFeeAddress) {
        _PlatformFeeAddress = PlatformFeeAddress;
    }

    // setter function that allows to set the _PrimarySaleAddress after deployment.
    function setPrimarySaleAddress(
        address PrimarySaleAddress
    ) external onlyOwner returns (address _PrimarySaleAddress) {
        _PrimarySaleAddress = PrimarySaleAddress;
    }

    // setter function that allows to set the _PermissionsAddress after deployment.
    function setPermissionsAddress(
        address PermissionsAddress
    ) external onlyOwner returns (address _PermissionsAddress) {
        return (_PermissionsAddress = PermissionsAddress);
    }

    // setter function that allows to set the _PermissionsEnumerableAddress after deployment.
    function setPermissionsEnumerableAddress(
        address PermissionsEnumerableAddress
    ) external onlyOwner returns (address _PermissionsEnumerableAddress) {
        return (_PermissionsEnumerableAddress = PermissionsEnumerableAddress);
    }

    // setter function that allows to set the _GaslessAddress after deployment.
    function setGaslessAddress(
        address GaslessAddress
    ) external onlyOwner returns (address _GaslessAddress) {
        return (_GaslessAddress = GaslessAddress);
    }

    /*///////////////////////////////////////////////////////////////
                            1.4. COMPLIANCE
    //////////////////////////////////////////////////////////////*/

    // KYC check function
    function kyc(
        address account,
        bool _kycStatus
    ) public onlyDEFAULT_ADMIN_ROLE returns (bool _compliance) {
        _compliance = _kycStatus;
        return _compliance;
    }

    // AML check function
    function aml(
        address _account,
        bool _amlStatus
    ) public onlyDEFAULT_ADMIN_ROLE returns (bool _compliance) {
        _compliance = _amlStatus;
        return _compliance;
    }

    // CFT check function
    function cft(
        address _account,
        bool _cftStatus
    ) public onlyDEFAULT_ADMIN_ROLE returns (bool _compliance) {
        _compliance = _cftStatus;
        return _compliance;
    }

    // Sanction enforcement
    function addressSanctioned(
        address _account,
        bool _status
    ) public onlyDEFAULT_ADMIN_ROLE returns (bool _sanction) {
        _sanction = _status;
        return _sanction;
    }

    /*///////////////////////////////////////////////////////////////
                           1.5. ROLE BASE CONTROLS FUNCTION 
    //////////////////////////////////////////////////////////////*/

    // setting up custom roles for subnet's abstract accounts.
    // the DEFAULT_ADMIN_ROLE is from "PermissionEnumerable" which provides role-based access control.

    /* GUEST processing: (could be an extension contract for BYOM)
        Login with unknown address implies creation of a GUEST account for that address,
        GUEST can see transactions on Explorer but is not allowed to submit any transaction,
        If this guest tries cashing-in or sending byoms to an existent account, he gets assigned CLIENT role if the address is compliant,
        Otherwise he has to request a role,
        If the _to address hasn't an account, he gets CLIENT role if he is compliant address.
        Any guest account can request a role by submiting a form.
    */

    /* Raising Suspected account to Authority: We need a function, in conjonction with AI, 
    /* for raising suspiscion before eventually tagging an account as sanctioned */
    /* POR processing: We need a function to verify POR any time. */

    function createGuest() public notAllowedRole {
        // Assign Guest role to an unknown caller address
        addressToRoleHash[msg.sender] = roleToBytes32[Role.GUEST_ROLE];
        // Log the newlly created guest account
        emit NewGuestCreated(msg.sender);
    }

    function createAccount(
        address _newAccount,
        Role _newAccountRole
    ) public onlyDEFAULT_ADMIN_ROLE {
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

    // Enforcing the role-based access control using wrappers.

    // !!!! should we  use contractAddress for all indirectly imported contracts other than TokenERC20?
    // As we won't be able to directly use the modifier onlyOwner for tese functions such as ContractMetadata.sol
    // since it's not directly in our control, we need a wrapper function.

    // 1. Wrapper function to approve account, only allowed for onlyAllowedADMIN_ROLE
    function byomApprove(address spender, uint256 amount) public onlyAdminRole {
        // Call the burn function from the imported contract
        approve(spender, amount);
    }

    // 2. Wrapper function to transfer byoms, only allowed for specific roles
    function byomTransfer(
        address from,
        address to,
        bool kycStatus,
        bool amlStatus,
        bool cftStatus,
        uint256 amount
    )
        public
        OnlyTRANSFER_ROLE
        OnlyAllowedRoles
        ComplianceCheck(from, to, kycStatus, amlStatus, cftStatus, amount)
    {
        // Call the transfer function from the imported contract
        transfer(to, amount);
    }

    // 3. Wrapper function to transferFrom byoms, only allowed for specific roles
    function byomTransferFrom(
        address from,
        address to,
        bool kycStatus,
        bool amlStatus,
        bool cftStatus,
        uint256 amount
    )
        public
        OnlyTRANSFER_ROLE
        AddressCheck(from, to)
        OnlyAllowedRoles
        ComplianceCheck(from, to, kycStatus, amlStatus, cftStatus, amount)
    {
        // Call the transfer function from the imported contract
        transferFrom(from, to, amount);
    }

    // 4. Wrapper function to burn byoms, only allowed for onlyAllowedADMIN_ROLE
    function byomBurn(uint256 amount) public onlyDEFAULT_ADMIN_ROLE {
        // Call the burn function from the imported contract
        burn(amount);
    }

    // 5. Wrapper function to burnFrom byoms , only allowed for onlyAllowedADMIN_ROLE
    function byomBurnFrom(
        address account,
        uint256 amount
    ) public onlyAdminRole {
        // Call the burnFrom function from the imported contract
        burnFrom(account, amount);
    }

    // 6. Wrapper function to mint byoms To, only allowed for onlyAllowedADMIN_ROLE role
    function byomMintTo(address to, uint256 amount) public OnlyMINTER_ROLE {
        // Call the mintTo function from the imported contract, TOKENERC20.sol
        mintTo(to, amount);
    }

    // 7. Wrapper function to grantRole , only allowed for specific roles
    function byomGrantRole(
        bytes32 role,
        address account
    ) public OnlyAllowedRoles {
        // Call the grantRole function from the imported contract
        grantRole(role, account);
    }

    // 8. Wrapper function to revokeRole , only allowed for specific roles
    function byomRevokeRole(
        bytes32 role,
        address account
    ) public OnlyAllowedRoles {
        // Call the revokeRole function from the imported contract
        revokeRole(role, account);
    }

    // 9. Wrapper function to renonceRole , only allowed for specific roles
    function byomRenounceRole(
        bytes32 role,
        address account
    ) public OnlyAllowedRoles {
        // Call the renonceRole function from the imported contract
        renounceRole(role, account);
    }

    // 10. Wrapper function to increaseAllowance , only allowed for specific roles
    function byomIncreaseAllowance(
        address spender,
        uint256 substractedValue
    ) public OnlyAllowedRoles {
        // Call the  function from the imported contract
        increaseAllowance(spender, substractedValue);
    }

    // 11. Wrapper function to delegate , only allowed for specific roles
    function byomDelegate(address delegatee) public OnlyAllowedRoles {
        // Call the delegate function from the imported contract
        delegate(delegatee);
    }

    // 12. Wrapper function to decreaseAllowance , only allowed for specific roles
    function byomDecreaseAllowance(
        address spender,
        uint256 substractedValue
    ) public OnlyAllowedRoles {
        // Call the  function from the imported contract
        decreaseAllowance(spender, substractedValue);
    }

    //13. Wrapper function to permit , only allowed for specific roles
    function byomPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyAdminRole {
        // Call the permeit function from the imported contract
        permit(owner, spender, value, deadline, v, r, s);
    }

    // 14. Wrapper function balanceOf byoms, only allowed
    function byomBalanceOf(
        address account
    ) public view OnlyAllowedRoles returns (uint256) {
        //
        balanceOf(account);
    }

    // 15. Wrapper function allowance byoms
    function byomAllowance(
        address owner,
        address spender
    ) public view OnlyAllowedRoles returns (uint256) {
        //
        allowance(owner, spender);
    }

    // 16.  Wrapper function totalSupply byoms
    function byomTotalSupply() public view OnlyAllowedRoles returns (uint256) {
        //
        totalSupply();
    }

    /*///////////////////////////////////////////////////////////////
                           1.6. Left Over
    //////////////////////////////////////////////////////////////*/

    /*     
            // 17. Wrapper function to mintWithSignature. Mints byoms according to the provided mint request
            function byomMintWithSignature(Req calldata req, bytes calldata signature) external payable onlyDEFAULT_ADMIN_ROLE {
                // Call the mintWithSignature function from the imported contract
                mintWithSignature((req.to, 
                req.primarySaleRecipient, 
                req.quantity, 
                req.price, 
                req.currency, 
                req.validityStartTimestamp,
                req.validityEndTimestamp,
                req.uid 
                ), signature);
            } 
            // 18. Wrapper function to multicall, only allowed for specific roles
            function byomMulticall(bytes[] calldata data) external onlyDEFAULT_ADMIN_ROLE {
                // Call the multicall function from the imported contract.
                multicall(data);
            }    
            // 19. Wrapper function to setPlatformFeeInfo , only allowed for specific roles
            function byomSetPlatformFeeInfo(address feeRecipient, uint256 feeBps) public onlyOwner {
                // Call the setPlatformFeeInfo function from the imported contract
                setPlatformFeeInfo(feeRecipient, feeBps);
            }
            // 19b. Wrapper function to getPlatformFeeInfo , only allowed for specific roles
            function byomGetPlatformFeeInfo() public onlyAllowedRoles {
                getPlatformFeeInfo():
            };

            // 20. Wrapper function to SetPrimarySaleRecipeint , only allowed for specific roles
            function byomSetPrimarySaleRecipient(address saleRecipient) public OnlyAllowedRoles {
                // Call the setPrimarySaleRecipeint function from the imported contract
                setPrimarySaleRecipient(msg.sender, saleRecipient);
            }
            // 21. Wrapper function to delegateBySig , only allowed for specific roles
            function byomDelegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 V, bytes32 R, bytes32 S) public OnlyAllowedRoles {
                // Call the delegateBySig function from the imported contract
                delegateBySig(msg.sender, delegatee, nonce, expiry, V, R, S);
            }
            /*
            modifier minimumRequire() {
                if (msg.value.getConversionRate() < MINIMUM_USD)
                    revert MiniAmountNotOk();
                _;
            } 
            
            // Client Deposit 
            function byomClientDeposit(, ) public onlyOn_RAMP_ROLE {

            }
            // Merchant Deposit 
            function byomMerchantDeposit(, )  public onlyOn_RAMP_ROLE {

            }
            // Ageant Deposit 
            function byomAgeantDeposit(, )  public onlyOn_RAMP_ROLE {

            }
            // PoS Deposit 
            function byomPoSDeposit(, )  public onlyOn_RAMP_ROLE {

            }

            // Client Withdrawal 
            function byomClientWithdrawal(, ) public OnlyClientRole {

            }
            // Merchant Withdrawal 
            function byomMerchantWithdrawal(, ) public OnlyMerchantRole {
        
            }
            // Ageant Withdrawal 
            function byomAgeantWithdrawal(, ) public OnlyAgeantRole {

            }
            // PoS Withdrawal 
            function byomPoSWithdrawal(, ) public OnlyPoSRole {
            
            }

            // Currency conversion
            function(, ) public OnlyAllowedRoles {

                nativeCurrencyPeg0;
                nativeCurrencyPeg1;
                nativeCurrencyPeg2;
                nativeCurrencyPeg3;
                nativeCurrencyPeg4;
                nativeCurrencyPeg5;
        
            }

            // Safeguard consummer's funds
            function(address por, uint256 amount) public OnlyOwnerRole {
            
            }
            */
}
