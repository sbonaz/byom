
/* /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    README:  creating a login interface for a BYOM application using React. 
    This interface allows users to connect their smart wallets to the application BYOM
    by entering a password.
    We can further enhance the user experience by adding error handling and messages for failed wallet connections. 
    Additionally, wwe can implement further functionality once the user is logged in, 
    such as displaying user-specific content or performing specific actions related to the BYOM application.    
////////////////////////////////////////////////////////////////////////////////////// /////////////////////////////*/

import { useState } from "react";
import styles from "../styles/Home.module.css";
import connectSmartWallet from "../lib/wallet";

export const ByomSwLogin = () => {

    // State Management: we are using React hooks like useState to manage state in our component
    const [signer, setSigner] = useState<any>(undefined);

    // We're using the setPassword function to update the password state when the user enters their password. 
    // This is a common approach for handling form inputs.
    const [password, setPassword]= useState<string>("");

    // Loading State: we are using the isLoading and loadingStatus states to handle the loading state of the component
    const [loadingStatus, setLoadingStatus] = useState<string>("");  
    
    // We display a loading message while the wallet is being connected, which is helpful for the user experience. 
    const [isLoading, setIsLoading] = useState<boolean>(false);

    // connectWallet Function: The connectWallet function is triggered when the "Login" button is clicked. 
    // It attempts to connect the smart wallet using the connectSmartWallet function, 
    // and then it sets the signer state if successful.

    const connectWallet = async () => {
        try {
            setIsLoading(true);
            const wallet = connectSmartWallet();
           // const wallet = await connectSmartWallet(password, (status: string) => setLoadingStatus(status));
            
            const s = await wallet.getSigner();
            setSigner(s);
            setIsLoading(false);

        } catch (error) {
            console.error(error);
        }       
    };

    // Conditional Rendering: we're conditionally rendering different parts of our component based on the state.
    return signer ? (
        <div>
            
        </div>
    ) : isLoading ? (
        <div className={styles.loginContainer}>
            <div className={styles.loginCard}>
                <p>{loadingStatus}</p>
            </div>
        </div>       
    ): (
        <div className={styles.loginContainer}>
            <div className={styles.loginCard}>
                <h1>Login</h1>
                <div>
                    <p>Enter password to access or create BYOM account</p>
                    <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)}/>
                </div>
                <button onClick={() => connectWallet()}>Login</button>
            </div>
        </div> 
    )
}