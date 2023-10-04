import { ThirdwebSDKProvider } from "@thirdweb-dev/react";
import { Signer } from "ethers";
import Navbar from "./Navbar";

export const Connected = ({
    signer,
}: {
    signer: Signer;
}) => {
    return (
        <ThirdwebSDKProvider
            signer = {signer}
            activeChain={"avalanche"}
            clientId={process.env.REACT_DAPP_BYOM_CLIENT_ID}
        >
            <ConnectedComponents/>
        </ThirdwebSDKProvider>
    )
};

const ConnectedComponents = () => {
    return (
        <div>
            <Navbar/>            
        </div>
    )
};