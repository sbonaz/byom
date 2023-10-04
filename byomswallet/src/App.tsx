import { ConnectWallet, Web3Button } from "@thirdweb-dev/react";
import "./styles/Home.css";

export default function App() {
  return (
    <main className="main">
      <div className="container">
        <ConnectWallet/>
        <Web3Button 
        contractAddress="0x997968E6c130239c7b02F19Fbb71d7e2a7136c7F"  
        action={(contract) => contract.erc20.balanceOf("0xba575771b24358E5CF1f2EF1b28886A9c988876c")}>Check BalanceOf</Web3Button>
      </div>
    </main>
  );
}
