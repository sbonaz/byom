import React, { useEffect, useState } from "react";

/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/ In this code, we use the useState and useEffect hooks to handle the asynchronous initialization of App. 
/ The useEffect hook is used to run the initialization code when the component mounts, 
/ and we store the fetched metadata in the component's state using setMetadata. 
/ This way, the component App is synchronous and only then it can be used as a JSX component.
/ ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

import { ConnectWallet } from "@thirdweb-dev/react";
import "./styles/Home.css";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";

export default function App() {
  const [metadata, setMetadata] = useState({ name: "", description: "" });

  useEffect(() => {
    async function initializeApp() {
      // =================== Initializing the SDK with the smart contract ==================== //

      const REACT_BYOM_CLIENT_ID = "047e74725405aa4df6709af71c54e10b";
      // Passing frontend's CLIENT id
      const sdk = new ThirdwebSDK("avalanche-fuji", {
        clientId: REACT_BYOM_CLIENT_ID,
      });
      // Getting Contract ADDRESS
      const contract = await sdk.getContract(
        "0xa8dBa53b88c90Bff2c692c2d0Eec69B26BdD0E80"
      );

      // =============================== METADATAs ========================================== //

      // Setting up contract's METADATAs (Set)
      await contract.metadata.set({
        name: "BYOM",
        description: "Innovative decentralized payment platform",
      });

      // Updating the contract's METADATAs (Update)
      await contract.metadata.update({
        description: "My new contract description",
      });

      // Reading the contract's METADATAs (get)
      const fetchedMetadata = await contract.metadata.get();
      setMetadata(fetchedMetadata);

      // Rest of your code...
    }

    initializeApp();
  }, []);

  return (
    <main className="main">
      {/* Rest of your JSX code */}
      <div className="connect">
        <ConnectWallet
          dropdownPosition={{
            side: "bottom",
            align: "center",
          }}
        />
      </div>
    </main>
  );
}
