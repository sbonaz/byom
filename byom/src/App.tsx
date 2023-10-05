
import React, { useEffect, useState, useRef  } from "react";

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/ In this code, we use the useState and useEffect hooks to handle the asynchronous initialization of App. 
/ The useEffect hook is used to run the initialization code when the component mounts, 
/ and we store the fetched metadata in the component's state using setMetadata. 
/ This way, the component App is synchronous and only then it can be used as a JSX component.
/ ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */


// To let TypeScript be aware of specific Thirdweb types, such as SmartContractwe, we are going to use, 
// we should import these  types from the appropriate package or module where it's defined.
import { ThirdwebSDK, SmartContract } from "@thirdweb-dev/sdk";

import { ConnectWallet } from "@thirdweb-dev/react";

import "./styles/Home.css";


export default function App() {

   // Create a ref to store the contract
   // By using a useRef to store the contract, we ensure that the contract value persists across renders 
   // and remains accessible within your component's functions (even outside useEffet( where it is set)).
   // Initialize contractRef with null. 
   // We need to use a type assertion to tell TypeScript that it will hold a SmartContract object later.
  const contractRef = useRef<SmartContract | null>(null);
  // In that way, TypeScript will allow us to assign contract to contractRef.current

  // Here, we use useState hooks to create state variables for each of the values that the user should input.

 // Using the useState hook to create a metadata state variable with an initial state containing empty name and description properties.
  const [metadata, setMetadata] = useState({ name: "", description: "" }); 

  const [spenderAddress, setSpenderAddress] = useState('');
  const [amountAllowed, setAmountAllowed] = useState(0);
  const [toAddressTransfer, setToAddressTransfer] = useState('');
  const [amountSent, setAmountSent] = useState(0);
  const [fromAddress, setFromAddress] = useState('');
  const [toAddress, setToAddress] = useState('');
  const [amount, setAmount] = useState(0);

  useEffect(() => {
    async function initializeApp() {
      // =================== Initializing the SDK with the smart contract ==================== //

      const REACT_BYOM_CLIENT_ID = "047e74725405aa4df6709af71c54e10b";
      // Passing frontend's CLIENT id
      const sdk = new ThirdwebSDK("avalanche-fuji", {
        clientId: REACT_BYOM_CLIENT_ID,
      });
      // Getting Contract ADDRESS
      const contract = await sdk.getContract("0xa8dBa53b88c90Bff2c692c2d0Eec69B26BdD0E80");

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

      // Reading the contract's METADATAs (get)
      const fetchedMetadata = await contract.metadata.get();
      const defaultDescription = "Default Description";
      const metadataWithDefaultDescription = {
        ...fetchedMetadata,
        description: fetchedMetadata.description || defaultDescription,
      };

      setMetadata(metadataWithDefaultDescription);

      }

  initializeApp();
  }, []);

  // ============================ Blockchain funtion calls ============================================= //
  // The following functions are used to perform the operations using the user-entered values from the state variables.
  // And the onChange event handlers are used to update the state variables as the user types.


  // ERC20 Extension: setting up token ALLOWANCE
  const handleSetAllowance = async () => {
  // Use spenderAddress and amountAllowed from state
    // Check if contractRef.current is defined before accessing its properties
    if (contractRef.current) {
      await contractRef.current.erc20.allowance(spenderAddress);
    };
  };
  // ERC20 Extension: TRANSFER tokens
  const handleTransferTokens = async () => {
  // Use toAddressTransfer and amountSent from state
    // Check if contractRef.current is defined before accessing its properties
      if (contractRef.current) {
        await contractRef.current.erc20.transfer(toAddressTransfer, amountSent);
      };
  }

  // ERC20 extension: Transfer token from a specific address
  const handleTransferFrom = async () => {
  // Use fromAddress, toAddress, and amount from state
      // Check if contractRef.current is defined before accessing its properties
      if (contractRef.current) {
       await contractRef.current.erc20.transferFrom(fromAddress, toAddress, amount);
      };
  }

  // ============================================================= //



  // ============================================================= //



  // ============================================================= //



  // ============================================================= //



  // ============================================================= //



  // ============================================================= //



  // ============================================================= //
    



  
  return (
    <main className="main">
      <div className="container">
        <div className="header">
          <h1 className="title">
            {" "} :, a Web3 innovation. 
            <span className="gradient-text-0">
              <a
                href="http://www.byom.fr/"
                target="_blank"
                rel="noopener noreferrer"
              >
                BYOM Platform.
              </a>
            </span>
          </h1>
          <p className="description">
            BYOM has been built with love to serve the future
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
            href="https://portal.thirdweb.com/"
            className="card"
            target="_blank"
            rel="noopener noreferrer"
          >
            <img
              src="/images/portal-preview.png"
              alt="Placeholder preview of starter"
            />
            <div className="card-text">
              <h2 className="gradient-text-1">Portal ➜</h2>
              <p>
                Guides, references, and resources that will help you build with
                thirdweb.
              </p>
            </div>
          </a>
          <a
            href="https://thirdweb.com/dashboard"
            className="card"
            target="_blank"
            rel="noopener noreferrer"
          >
            <img
              src="/images/dashboard-preview.png"
              alt="Placeholder preview of starter"
            />
            <div className="card-text">
              <h2 className="gradient-text-2">Dashboard ➜</h2>
              <p>
                Manage BYOM Platform from the
                dashboard.
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
              src="/images/templates-preview.png"
              alt="Placeholder preview of templates"
            />
            <div className="card-text">
              <h2 className="gradient-text-3">Templates ➜</h2>
              <p>
                More BYOM feature.
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
      <div>

        {/* input fields are created in the UI to collect user-entered values for metadata. */}

        <label>
          Name:
          <input
            type="text"
            value={metadata.name}
            onChange={(event) => {
              // Update the metadata.name property when the user types. 
              // we use the value prop to set the input field "name" based on the metadata state
              setMetadata({
                ...metadata,
                name: event.target.value,
              });
            }}
          />
        </label>
        <label>
          Description:
          <input
            type="text"
            value={metadata.description}
            onChange={(event) => {
              // Update the metadata.description property when the user types.
              // we use the value prop to set the input field "description" based on the metadata state
              setMetadata({
                ...metadata,
                description: event.target.value,
              });
            }}
          />
        </label>

        {/* input fields are created in the UI to collect user-entered values for Allowance and transfer. */}

        <input
          type="text"
          placeholder="Spender Address"
          value={spenderAddress}
          onChange={(e) => setSpenderAddress(e.target.value)}
        />



        {/* input forms are created in the UI to collect user-entered values for other functions. */}


        {/* Buttons */}
        {/* Left over 
            <button type="submit" onClick={handleNameChange}>Contract Name</button>
            <button type="submit" onClick={handleDescriptionChange}>Contract Description</button>
        */}

        <button type="button" onClick={handleSetAllowance}>Set Allowance</button>

        <button type="submit" onClick={handleTransferTokens}>Transfer Tokens</button>

        <button type="submit" onClick={handleTransferFrom}>Transfer From</button>

      </div>
    </main>
  );
}