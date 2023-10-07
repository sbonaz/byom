
// React Hooks used in this code
import React, { useEffect, useState, useRef  } from "react";

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/ In this code, we use the useState and useEffect hooks to handle the asynchronous initialization of App. 
/ The useEffect hook is used to run the initialization code when the component mounts, 
/ and we store the fetched metadata in the component's state using setMetadata. 
/ This way, the component App is synchronous and only then it can be used as a JSX component.
/ ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


// To let TypeScript be aware of specific Thirdweb types, such as SmartContract we are going to use, 
// we should import these  types from the appropriate package or module where it's defined.
import { ThirdwebSDK, SmartContract } from "@thirdweb-dev/sdk";

import { ConnectWallet } from "@thirdweb-dev/react";

import "./styles/Home.css";      // for styling


export default function App() {

   // We need to create a ref to store the contract.
   // By using a useRef to store the contract, we ensure that the contract value persists across renders 
   // and remains accessible within our component's functions (even outside useEffet( where it is set)).
   // Initialize contractRef with null. 
   // We need to use a type assertion to tell TypeScript that it will hold a SmartContract object, later.
  const contractRef = useRef<SmartContract | null>(null);
  // That way, TypeScript will allow us to assign contract to contractRef.current

  // Now, we use useState hooks to create state variables for each of the values that the user should input.
  // Using the useState hook to create the metadata object state variable 
  // with an initial state containing empty name and description properties.
  const [metadata, setMetadata] = useState({ name: "", description: "" }); 
  const [spenderAddress, setSpenderAddress] = useState('');
  const [amountAllowed, setAmountAllowed] = useState(''); // Initialize as an empty string
  const [toAddressTransfer, setToAddressTransfer] = useState('');
  const [amountSent, setAmountSent] = useState(''); // Initialize as an empty string
  const [fromAddress, setFromAddress] = useState('');
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState(''); // Initialize as an empty string

  useEffect(() => {
    async function initializeApp() {

      // =================== Initializing the SDK with the smart contract ==================== //
    
      const REACT_BYOM_CLIENT_ID = "047e74725405aa4df6709af71c54e10b";

      // Passing frontend's CLIENT id
      const sdk = new ThirdwebSDK("avalanche-fuji", {
        clientId: REACT_BYOM_CLIENT_ID,
      });
      // Getting Contract ADDRESS              0xa8dBa53b88c90Bff2c692c2d0Eec69B26BdD0E80
      const contract = await sdk.getContract("0x0a10258F48fE15053CB5CfbFfc2a6CB84Bf1AB12");
      
      // Assign the contract to the ref
      contractRef.current = contract;

      // =============================== METADATAs ========================================== //

      // Setting up contract's METADATAs (Set)
      await contract.metadata.set({
        name: "BYOM",
        description: "Innovative decentralized payment platform",
      });
      await contract.metadata.update({
        description: "My new contract description",
      });

      /* Reading the contract's METADATAs (get)
      We check if fetchedMetadata.name and fetchedMetadata.description are undefined, 
      and if so, we provide default values or convert them to empty strings before setting the metadata state. 
      This ensures that the metadata state always has the expected shape with string values.
      */
      const fetchedMetadata = await contract.metadata.get();
      const defaultDescription = "BYOM, a Compliant Payment System"; // Provide a default description here
      const metadataWithDefaultDescription = {
        name: fetchedMetadata.name || "",
        description: fetchedMetadata.description || defaultDescription,
      };

setMetadata(metadataWithDefaultDescription);

      }

  initializeApp();
  }, []);

  // ============================ Blockchain funtion's calls ============================================= //
  // The following functions are used to perform the operations using the user-entered values from the state variables.
  // And the onChange event handlers are used to update the state variables as the user types.

  const handleNameChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    event.preventDefault(); // Prevent default form submission
    if (contractRef.current) {
      await contractRef.current.metadata.set({
        ...metadata,
        name: event.target.value,
      });
    }
  };

  const handleDescriptionChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    event.preventDefault(); // Prevent default form submission
    if (contractRef.current) {
      await contractRef.current.metadata.set({
        ...metadata,
        description: event.target.value,
      });
    }
  };

  const handleSubmitMetadata = async (event: React.FormEvent) => {
    event.preventDefault(); // Prevent default form submission
    // Update metadata here using handleNameChange and handleDescriptionChange
    if (contractRef.current) {
      await handleNameChange(event as React.ChangeEvent<HTMLInputElement>); // Call the function to update Name
      await handleDescriptionChange(event as React.ChangeEvent<HTMLInputElement>); // Call the function to update Description
    }
  };

  // ERC20 Extension: setting up token ALLOWANCE
  const handleSetAllowance = async (event: React.FormEvent) => {
    // Use spenderAddress and amountAllowed from state
      // Check if contractRef.current is defined before accessing its properties
    event.preventDefault(); // Prevent default form submission
    if (contractRef.current) {
      await contractRef.current.erc20.allowance(spenderAddress);
    }
  };

    // ERC20 Extension: TRANSFER tokens
  const handleTransferTokens = async (event: React.FormEvent) => {
    event.preventDefault(); // Prevent default form submission
        // Use toAddressTransfer and amountSent from state
        // Check if contractRef.current is defined before accessing its properties
    if (contractRef.current) {
      await contractRef.current.erc20.transfer(toAddressTransfer, amountSent);
    }
  };

  // ERC20 extension: TRANSFER token FROM a specific address
  const handleTransferFrom = async (event: React.FormEvent) => {
    event.preventDefault(); // Prevent default form submission
  // Use fromAddress, toAddress, and amount from state
      // Check if contractRef.current is defined before accessing its properties
    if (contractRef.current) {
      await contractRef.current.erc20.transferFrom(fromAddress, toAddress, amount);
    }
  };

  return (
    <main className="main">

      <div className="container">
        <div className="header">
          <h1 className="title">
            {" "} BYOM   
            <span className="gradient-text-0">
              <a
                href="http://www.byom.fr/"
                target="_blank"
                rel="noopener noreferrer"
              >
               ... a Web3 innovation
              </a>
            </span>
          </h1>
          <p className="description">
            Compliant Cross Border Payment System, built with love to serve the future of diasporas
          </p>
          <div className="connect">
            <ConnectWallet
              dropdownPosition={{
                side: "bottom",
                align: "center",
              }}
            />
          </div>
        </div>
        <div className="grid">
          <a
            href="https://thirdweb.com/dashboard"
            className="card"
            target="_blank"
            rel="noopener noreferrer"
          >
            <img
              src="/images/C2MTransfer.png"
              alt="Placeholder preview of starter"
            />
            <div className="card-text">
              <h2 className="gradient-text-2">Money Transfer ➜</h2>
              <p>
                C2C Transfer.
              </p>
            </div>
          </a>

          <a
            href="https://thirdweb.com/templates"
            className="card"
            target="_blank"
            rel="noopener noreferrer"
          >
            <img
              src="/images/templates-C2CTransfer.png"
              alt="Placeholder preview of templates"
            />
            <div className="card-text">
              <h2 className="gradient-text-3"> Merchant Payment ➜</h2>
              <p>
                C2M Transfer.
              </p>
            </div>
          </a>
        </div>
      </div>
      
      <div className="connect">
        <ConnectWallet
          dropdownPosition={{
            side: "bottom",
            align: "center",
          }}
        />
      </div>

        {/* To allow users to input the values for given variables*/}

        {/* input fields are created in the UI to collect user-entered values for metadata. */}
        <div>
           <form onSubmit={handleSubmitMetadata}>
    <label>
      Name:
      <input
        type="text"
        value={metadata.name}
        placeholder="Name"
        onChange={(e) => setMetadata({ ...metadata, name: e.target.value })}
      />
    </label>
    <label>
      Description:
      <input
        type="text"
        value={metadata.description}
        placeholder="Description"
        onChange={(e) => setMetadata({ ...metadata, description: e.target.value })}
      />
    </label>
    <button type="submit">Contract Metadata</button>
          </form>
        </div>

        {/* input fields are created in the UI to collect user-entered values for Allowance and transfer. */}
        <div>
          <form onSubmit={handleSetAllowance}>
            <label>
            Spender Address:     
            <input
              type="text"
              value={spenderAddress}
              placeholder="Spender Address"
              onChange={(e) => setSpenderAddress(e.target.value)}
            />
            </label>      
            <label>
            Allowance:     
            <input
              type="text"
              value={amountAllowed}
              placeholder="Amount Allowed"
             onChange={(e) => setAmountAllowed(e.target.value)}
            />
            </label>
            <button type="submit">Tokens Allowance</button>
          </form>
        </div>

        {/* input forms are created in the UI to collect user-entered values for other functions. */}
        <div>
  <form onSubmit={handleTransferTokens}>
    <label>
      To Address:
      <input
        type="text"
        value={toAddressTransfer}
        placeholder="0x0..."
        onChange={(e) => setToAddressTransfer(e.target.value)}
      />
    </label>
    <label>
      Amount Sent:
      <input
        type="number"
        value={amountSent}
        onChange={(e) => setAmountSent(e.target.value)}
      />
    </label>
    <button type="submit">Transfer Tokens</button>
  </form>
       </div>

      <div>
  <form onSubmit={handleTransferFrom}>
    <label>
      From Address:
      <input
        type="text"
        value={fromAddress}
        placeholder="0x0..."
        onChange={(e) => setFromAddress(e.target.value)}
      />
    </label>
    <label>
      To Address:
      <input
        type="text"
        value={toAddress}
        placeholder="0x0..."
        onChange={(e) => setToAddress(e.target.value)}
      />
    </label>
    <label>
      Amount Sent:
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />
    </label>
    <button type="submit">TransferFrom Tokens</button>
  </form>
     </div>

    </main>
  );
}