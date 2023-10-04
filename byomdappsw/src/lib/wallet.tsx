import { Avalanche } from "@thirdweb-dev/chains";
import { SmartWallet, LocalWallet } from "@thirdweb-dev/wallets";
import { ThirdwebSDK, isContractDeployed } from "@thirdweb-dev/sdk";

import { BYOM_CONTRACT_ADDRESS } from "../../constants/addresses";


const chain = Avalanche;

// A function that returns back an object of type SmartWallet.
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

// Function that connects the newlly created smartWallet to the chain through a factory contract with 2 arguments needed
export async function connectSmartWallet(
    password: string,
    statusCallback: (status: string) => void   // ?
    ): Promise<SmartWallet> {
        statusCallback("Searching for byomactor account...");
        const smartWallet = createSmartWallet();
        const personalWallet = new LocalWallet();
        await personalWallet.loadOrCreate({
            strategy: "encryptedJson", 
            password: password,
        });
        await smartWallet.connect({
            personalWallet
        });  

        const sdk = await ThirdwebSDK.fromWallet(
            smartWallet,
            chain,
            {
                clientId: process.env.REACT_DAPP_BYOM_CLIENT_ID,
            }
        );

        // If the contract has already been deployed ...
        const address = await sdk.wallet.getAddress();
        const isDeployed = await isContractDeployed(address, sdk.getProvider(), );

        // If the contract hasn't already been deployed ...
        if (!isDeployed) {

            // connecting with unexist account
            statusCallback("New account detected...");
            const byomContract = await sdk.getContract(BYOM_CONTRACT_ADDRESS); 

            // we create an account for this unknown actor
            statusCallback("Creating new account...");
            // Creating first transactions
            const tx1 = await byomContract.erc20.transfer("0x48148b0268B7FfeeEb9B1E402220135e62bF077D", 0.0002);
            const tx2 = await byomContract.erc20.claim.prepare(0.0001);
            const Tx = [tx1, tx2];
            // Sending batch transactions
            statusCallback("Sending initial funds...");
            const batchTx = await smartWallet.executeBatch(Tx);
            console.log(batchTx);
        } 
        else {
            statusCallback("Trainer account found! Loading monster...");         
        }
        return smartWallet;
};