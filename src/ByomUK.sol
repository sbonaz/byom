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

// TokenERC20Address : 0x04cdaaDCcb15214357fa65547E32BbEE3017988c and
// TokenERC20FactoryAddress: 0x5DBC7B840baa9daBcBe9D2492E45D7244B54A2A0, on Fuji

contract BYOMUk is TokenERC20 {
    /// +types
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.1. CUSTOM TYPES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
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

    /// +immutables and constantes
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.2.IMMUTABLES / CONSTANTES  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

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
        GUEST_ROLE,
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
    // bool private initialized; // Flag to track contract initialization
    Role public roleAssigned;
    // Native currency for compliant DeFi
    uint256 public nativeCurrencyDecimals;
    uint256 public nativeCurrencyPeg;
    uint256 public nativeCurrencyPegRate;
    // Dictionary
    mapping(Role => bytes32) public roleToBytes32;
    mapping(address => bytes32) public addressToRoleHash;
    // List of role hashes
    bytes32[] public roleHashes;

    /// +errors
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.4. E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
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
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.5.  M O D I F I E R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    // Modifier to allow only specific roles to execute certain functions
    modifier OnlyAllowedRoles() {
        require(
            hasRole(roleToBytes32[Role.CLIENT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.MERCHANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.PoS_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AGEANT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AMBASSADOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SUPPORT_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.POR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.ADMIN_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUDITOR_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.AUTHORITY_ROLE], msg.sender) ||
                hasRole(roleToBytes32[Role.SANCTIONER_ROLE], msg.sender),
            "Caller does not have the required role"
        );
        _;
    }
    // Enforcing the role-based access control.
    modifier onlyClientRole() {
        require(
            hasRole(roleToBytes32[Role.CLIENT_ROLE], msg.sender),
            "Caller does not have the CLIENTrole"
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
            hasRole(roleToBytes32[Role.POR_ROLE], msg.sender),
            "Caller does not have the POR role"
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
        bool cftStatus //  bool sanctionStatus
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
    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 0.6. E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

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
    event NewGuestCreated(address account);

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
            keccak256("GUEST_ROLE"),
            keccak256("CLIENT_ROLE"),
            keccak256("MERCHANT_ROLE"),
            keccak256("PoS_ROLE"),
            keccak256("AGEANT_ROLE"),
            keccak256("MERCHANT_ROLE"),
            keccak256("AMBASSADOR_ROLE"),
            keccak256("AUTHORITY_ROLE"),
            keccak256("SANCTIONER_ROLE"),
            keccak256("AUDITOR_ROLE"),
            keccak256("ADMIN_ROLE"),
            keccak256("SUPPORT_ROLE"),
            keccak256("POR_ROLE") // Proof of Reserve
        ];

        /*      grantRole(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            _defaultAdmin
        );
*/
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

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.3. EXTENSION CONTRACT'S ADDRESS SETTERS @@@@@@@@@@@@@@@@@@@@@ */

    address _contractMetadataAddress;
    address _ERC20Address;
    address _ERC20BurnableAddress;
    address _ERC20SignatureMintableAddress;
    address _ERC20PermitAddress;
    address _PlatformFeeAddress;
    address _ERC20BatchMintableAddress;
    address _ERC20MintableAddress;

    // setter function that allows to set the _contractMetadataAddress after deployment.
    function setContractMetadataAddress(
        address metadataAddress
    ) external onlyOwner {
        _contractMetadataAddress = metadataAddress;
    }

    // setter function that allows to set the _ERC20Address after deployment.
    function setERC20Address(address ERC20Address) external onlyOwner {
        _ERC20Address = ERC20Address;
    }

    // setter function that allows to set the _ERC20BurnableAddress after deployment.
    function setERC20BurnableAddress(
        address ERC20BurnableAddress
    ) external onlyOwner {
        _ERC20BurnableAddress = ERC20BurnableAddress;
    }

    // setter function that allows to set the _ERC20MintableAddress after deployment.
    function setERC20MintableAddress(
        address ERC20MintableAddress
    ) external onlyOwner {
        _ERC20MintableAddress = ERC20MintableAddress;
    }

    // setter function that allows to set the _ERC20BatchMintableAddress after deployment.
    function setERC20BatchMintableAddress(
        address ERC20BatchMintableAddress
    ) external onlyOwner {
        _ERC20BatchMintableAddress = ERC20BatchMintableAddress;
    }

    // setter function that allows to set the _ERC20SignatureMintableAddress after deployment.
    function setERC20SignatureMintableAddress(
        address ERC20SignatureMintableAddress
    ) external onlyOwner {
        _ERC20SignatureMintableAddress = ERC20SignatureMintableAddress;
    }

    // setter function that allows to set the _ERC20PermitAddress after deployment.
    function setERC20PermitAddress(
        address ERC20PermitAddress
    ) external onlyOwner {
        _ERC20PermitAddress = ERC20PermitAddress;
    }

    // setter function that allows to set the _PlatformFeeAddress after deployment.
    function setPlatformFeeAddress(
        address PlatformFeeAddress
    ) external onlyOwner {
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

    /* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1.4. ROLE BASE FUNCTION CONTROLS @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */

    // setting up custom roles for subnet's abstract accounts.
    // the default admin role is from "PermissionEnumerable" which provides role-based access control.

    /* GUEST processing:
        Login with unknown address implies creation of a GUEST account for that address,
        GUEST can see transsctions on Explorer but is not allowed to submit any transaction,
        If this guest tries cashing-in or sending byoms to an existent account, he gets assigned CLIENT role if the address is compliant,
        Otherwise he has to request a role,
        If the _to address hasn't an account, he gets CLIENT role if he is compliant address.
        Any guest account can request a role by submiting a form.
    */

    /* raising SUSPISCION to Authority: We need a function to raise suspiscion before eventually tagging an account as sanctioned */

    /* POR processing: We need a function to verify POR any time. */

    function createGuest() public {
        // Assign Guest role to the provided address
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

    // Enforcing the role-based access control usint wrappers.

    // 0. For ContractMetadata. !!!! we should do that for all extensions other than TokenERC20.
    // As we won't be able to directly use the modifier onlyOwner for functions from ContractMetadata.sol
    // since it's not directly in our control, we need a wrapper function.

    /*
    function setContractURI(string memory uri) public onlyOwner {
        // Call the setContractURI function from the imported ContractMetadata contract in TokenERC20 contract.
        ContractMetadata(_contractMetadataAddress).setContractURI(uri);
    }
*/

    // 1. Wrapper function to approve account, only allowed for onlyAllowedADMIN_ROLE
    function approveByomAccount(
        address spender,
        uint256 amount
    ) public onlyAdminRole {
        // Call the burn function from the imported contract
        _approve(msg.sender, spender, amount);
    }

    // 2. Wrapper function to transfer byoms, only allowed for specific roles
    function transferByoms(
        address to,
        bool kycStatus,
        bool amlStatus,
        bool cftStatus,
        uint256 amount
    )
        public
        OnlyAllowedRoles
        ComplianceCheck(msg.sender, to, kycStatus, amlStatus, cftStatus)
    {
        // Call the transfer function from the imported contract
        _transfer(msg.sender, to, amount);
    }

    // 3. Wrapper function to transferFrom byoms, only allowed for specific roles
    function transferByomsFrom(
        address from,
        address to,
        bool kycStatus,
        bool amlStatus,
        bool cftStatus,
        uint256 amount
    )
        public
        AddressCheck(from, to)
        OnlyAllowedRoles
        ComplianceCheck(from, to, kycStatus, amlStatus, cftStatus)
    {
        // Call the transfer function from the imported contract
        transferFrom(from, to, amount);
    }

    // 4. Wrapper function to burn byoms, only allowed for onlyAllowedADMIN_ROLE
    function burnByoms(uint256 amount) public onlyDEFAULT_ADMIN_ROLE {
        // Call the burn function from the imported contract
        burn(amount);
    }

    // 5. Wrapper function to burnFrom byoms , only allowed for onlyAllowedADMIN_ROLE
    function burnByomsFrom(
        address account,
        uint256 amount
    ) public onlyAdminRole {
        // Call the burnFrom function from the imported contract
        burnFrom(account, amount);
    }

    // 6. Wrapper function to mint byoms To, only allowed for onlyAllowedADMIN_ROLE role
    function mintByomsTo(
        address to,
        uint256 amount
    ) public onlyDEFAULT_ADMIN_ROLE {
        // Call the mintTo function from the imported contract, TOKENERC20.sol
        mintTo(to, amount);
    }

    /*  7. Wrapper function to multicall, only allowed for specific roles
    function multicallByom(
        bytes[] calldata data
    ) public onlyDEFAULT_ADMIN_ROLE {
        // Call the multicall function from the imported contract.
        multicall(data);
    }
    */

    // 8. Wrapper function to multicall , only allowed for specific roles
    function permitByomAccount(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 V,
        bytes32 R,
        bytes32 S
    ) public onlyAdminRole {
        // Call the xxxx function from the imported contract
        permit(owner, spender, value, deadline, V, R, S);
    }

    /*     
    // 9. Wrapper function to multicall , only allowed for specific roles
    function mintByomWithSignature() public onlyDEFAULT_ADMIN_ROLE {
        // Call the xxxx function from the imported contract
        _mintWithSignature(msg.sender, );
    }
    // 10. Wrapper function to multicall , only allowed for specific roles
    function setByomPlatformFeeInfoByom(msg.sender, ) public onlyDEFAULT_ADMIN_ROLE {
        // Call the xxxx function from the imported contract
        _setPlatformFeeInfo(msg.sender, );
    }  
    // 11. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 12. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 13. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 14. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 15. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 16. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 17. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 18. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 19. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 20. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 21. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
    // 22. Wrapper function to multicall , only allowed for specific roles
    function(msg.sender, ) public OnlyAllowedRoles {
        // Call the xxxx function from the imported contract
    }
*/
}
