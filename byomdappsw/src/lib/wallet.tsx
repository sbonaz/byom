
/* /////////////////////////////////////////////////////////////////////////////////////
    README: this code aimes at creating and connecting a SmartWallet (standard ERC4337) 
    to interact with a smart contract (TokenERC20) on the Avalanche Fuji testnet.
    Setting up and connecting a SmartWallet effectively and
    handling the scenario where the associated contract may or may not have been deployed.
////////////////////////////////////////////////////////////////////////////////////// */

// Importing the necessary modules and constants.
import { AvalancheFuji } from "@thirdweb-dev/chains";
import { SmartWallet, LocalWallet } from "@thirdweb-dev/wallets";
import { ThirdwebSDK, isContractDeployed } from "@thirdweb-dev/sdk";
import { BYOMFr_CONTRACT_ADDRESS } from "../constants/addresses";

const chain = AvalancheFuji;

/*  A function that creates a new SmartWallet instance. It returns back an object of type SmartWallet.
    This function takes no arguments and configures the SmartWallet with relevant parameters such as:
    - the blockchain chain, 
    - factory address, 
    - gasless option, and 
    - client ID. 
*/
 export default function createSmartWallet(): SmartWallet {  
    // we create a new SmartWallet by passing 4 arguments
    const smartWallet = new SmartWallet({ 
        chain: "avalanche",
        factoryAddress: "0xAdF84ce6aAd25Cd7eAD5803A08483b2878Fb2213",
        gasless: true,
        clientId: process.env.REACT_DAPP_BYOM_CLIENT_ID,
    });
    return smartWallet;
};

/*   Asynchronous function connectSmartWallet that connects the SmartWallet to the blockchain. 
     It takes two arguments:
    - Password, for the wallet encryption and
    - statusCallback, to provide status updates.
*/
export async function connectSmartWallet(
    password: string,
    statusCallback: (status: string) => void
    ): Promise<SmartWallet> {
        statusCallback("Searching for byomActor account...");
        const smartWallet = createSmartWallet();  // Creating an instance of SmartWallet using createSmartWallet.
        const personalWallet = new LocalWallet(); 
        await personalWallet.loadOrCreate({      // Creating a LocalWallet instance and load or create a wallet using encryption.
            strategy: "encryptedJson", 
            password: password,
        });
        await smartWallet.connect({  // Connecting the SmartWallet to the LocalWallet. 
            personalWallet
        });  
        //  Initializing the Thirdweb SDK with the SmartWallet and chain information. 
        const sdk = await ThirdwebSDK.fromWallet(
            smartWallet,
            chain,
            {
                clientId: process.env.REACT_DAPP_BYOM_CLIENT_ID,
            }
        );

         // Checking if the contract associated with the wallet address has already been deployed using the isContractDeployed function.
        const address = await sdk.wallet.getAddress();
        const isDeployed = await isContractDeployed(address, sdk.getProvider(), );

        // Handling Contract Deployment: Depending on whether the contract has already been deployed, 
        // the code either creates a new account and funds it or logs a message indicating that the account is found.

        /*  If the contract hasn't already been deployed, we assume it's a new account and perform the following actions:
                - Log a status message.
                - Get the byomContract using the contract address.
                - Create two transactions: one for transferring tokens and one for preparing a claim.
                - Send the batch transactions.
        */

        if (!isDeployed) {
            statusCallback("New account detected...");
    
            const byomContract = await sdk.getContract(BYOMFr_CONTRACT_ADDRESS);
    
            statusCallback("Creating new account...");
    
            // Create and send transactions directly using contract methods
            await byomContract.erc20.transfer("0x48148b0268B7FfeeEb9B1E402220135e62bF077D", 0.0002);
            await byomContract.erc20.claim.prepare(0.0001);
    
            statusCallback("Sending initial funds...");
        } else {
            statusCallback("Byomer account found! Loading ByomAd...");
        }
        return smartWallet; // Add this line to ensure a consistent return type
}