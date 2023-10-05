import { ConnectWallet } from "@thirdweb-dev/react";
import "./styles/Home.css";
import { ThirdwebSDK } from "@thirdweb-dev/sdk";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

export default async function App() {

  // =================== Initializing the SDK with the smart contract ==================== //

  const REACT_BYOM_CLIENT_ID = "047e74725405aa4df6709af71c54e10b";
  // Passing fontend's CLIENTid
    const sdk = new ThirdwebSDK("avalanche-fuji", {clientId: "REACT_BYOM_CLIENT_ID",});
  // Getting Contract ADDRESS
   const contract = await sdk.getContract("0xa8dBa53b88c90Bff2c692c2d0Eec69B26BdD0E80");

  // =============================== METADATAs ========================================== //

  // Setting up contract's METADATAs (Set)
    await contract.metadata.set({
      name: "BYOM",
      description: "Innovative decentralized payment platform"
    });

  // Updating the contract's METADATAs (Update)
    await contract.metadata.update({
      description: "My new contract description"
    })

  // Reading the contract's METADATAs (get)
    const metadata = await contract.metadata.get();
    console.log(metadata);

  // ============================ ALLOWANCE ============================================= //

  // ERC20 Extension: setting up token ALLOWANCE
   // Address of the wallet to allow transfers from 
  const spenderAddress = "0x...";  
   // The number of tokens to give as ALLOWANCE
  const amountAllowed = 100;
  await contract.erc20.setAllowance(spenderAddress, amountAllowed);

  // ERC20 Extension: TRANSFER tokens
    // Address of the wallet you want to send the tokens to
  const toAddressTransfer = "0x...";
    // The amount of tokens you want to send
  const amountSent = 0.1;
  await contract.erc20.transfer(toAddressTransfer, amountSent);

  // ERC20 extension: Transfer token from a specific address
    // Address of the wallet sending the tokens
  const fromAddress = "0x106150578098F4Ac8AD8b0f6f806658D4F2eDeD7";
  // Address of the wallet you want to send the tokens to
  const toAddress = "0x...";
  // The number of tokens you want to send
  const amount = 1.2
  // Note that the connected wallet must have approval to transfer the tokens of the fromAddress
  await contract.erc20.transferFrom(fromAddress, toAddress, amount);

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
    </main>
  );
}
