import React from "react";
import { createRoot } from "react-dom/client";
import ByomSw from "./ByomSw";
import reportWebVitals from "./reportWebVitals";
import { ThirdwebProvider } from "@thirdweb-dev/react";
import "./styles/globals.css";
import { AvalancheFuji } from "@thirdweb-dev/chains";

// Here is the chain our dApp will work on.
// Change this to the chain your app is built for.
// one can also import additional chains from `@thirdweb-dev/chains` and pass them directly.
const activeChain = AvalancheFuji;

const container = document.getElementById("rootByom");
const root = createRoot(container!);
root.render(
  <React.StrictMode>
    <ThirdwebProvider
      activeChain={activeChain}
      clientId={process.env.REACT_DAPP_BYOM_CLIENT_ID}
    >
      <ByomSw/>
    </ThirdwebProvider>
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
