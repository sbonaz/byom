import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import reportWebVitals from "./reportWebVitals";
import { ThirdwebProvider, paperWallet, smartWallet } from "@thirdweb-dev/react";
import "./styles/globals.css";

// This is the chain your dApp will work on.
// Change this to the chain your app is built for.
// You can also import additional chains from `@thirdweb-dev/chains` and pass them directly.
const activeChain = "avalanche";

const container = document.getElementById("root");
const root = createRoot(container!);
root.render(
  <React.StrictMode>
    <ThirdwebProvider
      activeChain={activeChain}
      clientId={process.env.BYOM_SMART_WALLET_CLIENT_ID}
      supportedWallets={[
        smartWallet({
          factoryAddress: "0xAdF84ce6aAd25Cd7eAD5803A08483b2878Fb2213",
          gasless: true,
          personalWallets: [
            paperWallet({
              paperClientId:"5801f7d5-7b3c-42b7-96f6-9917d978bb48"   // paper.xyz Auth
            })
          ]
        })
      ]}
    >
      <App />
    </ThirdwebProvider>
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
