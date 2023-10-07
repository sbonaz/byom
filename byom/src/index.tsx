import React from "react";
import { createRoot } from "react-dom/client";
import ByomWebApp from "./ByomWebApp";
import { ThirdwebProvider } from "@thirdweb-dev/react";
import { AvalancheFuji } from "@thirdweb-dev/chains";
import "./styles/globals.css";
import reportWebVitals from "./reportWebVitals";

// Defining the chain the dApp will work on.
// One can also import additional chains from `@thirdweb-dev/chains` and pass them directly.
const activeChain = AvalancheFuji;
// ex: Avalanche Fuji Testnet

const container = document.getElementById("react-goes-here");
const root = createRoot(container!);
root.render(
  <React.StrictMode>
    <ThirdwebProvider
      activeChain={activeChain}
      clientId={process.env.REACT_BYOM_CLIENT_ID}
    >
      <ByomWebApp/>
    </ThirdwebProvider>
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
