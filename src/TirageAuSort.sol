// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "node_modules/@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract TirageAuSort is ContractMetadata {
    // Déclaration sous forme d'énumération (enum) des deux faces d'une piece
    enum PileOuFace {
        PILE,
        FACE
    }
    // Déclaration sous forme d'énumération des deux résultats possibles d'un jet
    enum ResultatDuJet {
        GAGNE,
        PERDU
    }

    // Définition du format d'enregistrement d'informations (joueur, côté choisi et résultat du jet)
    event ResultatAenregistre(
        address indexed joueur, // donnée indexée, on pourra donc faire une recherche sur ce critère
        PileOuFace coteChoisi,
        ResultatDuJet resultat
    );

    /**
     *  On sauvegarde l'address du propriétaire du contract dans la variable 'owner'
     *  Ceci sera nécessaire pour l'utilisation de l'extension `ContractMetadata`.
     */
    address public owner;

    // La fonction à exécution unique
    constructor() {
        owner = msg.sender;
    }

    // La fonction permettant d'utiliser l'extension `ContractMetadata`.
    /**
     * Cette fonction renvoit l'adresse de celui qui est autorisé à positionner les metadata de ce contract.
     */
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner;
    }

    // Fonction jet de pièce. Prend en compte le choix, Pile ou Face, du joueur
    function jetDePiece(PileOuFace coteChoisi) public {
        // Voici le mécanisme de jet de pièce qui donne un résultat aléatoire
        uint256 nombreAleatoir = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 2;

        // Voici la variable qui stocke le résultat du jet une fois converti en Pile ou Face
        PileOuFace resultat = PileOuFace(nombreAleatoir);

        // Verdict: comparaison côté choisi (argument de la fonction) et résultat aléatoire.
        ResultatDuJet resultatDuJet = (coteChoisi == resultat)
            ? ResultatDuJet.GAGNE
            : ResultatDuJet.PERDU;

        // Informations enregistrées: adresse du joueur, son choix, le résultat du jet.
        emit ResultatAenregistre(msg.sender, coteChoisi, resultatDuJet);
    }
}

/*  README
a simple smart contract called CoinFliper for a coin flipping game. In this game, a joueur can choose either "PILE" or "FACE," and the smart contract generates a random outcome to determine if the joueur wins or loses.

Let's break down the code step by step:

Solidity Version: This line specifies the version of the Solidity compiler that should be used for compiling this contract. In this case, it's set to ^0.8.10, which means any Solidity compiler version from 0.8.10 up to, but not including, 0.9.0 can be used.

Enum Definitions: Two enums are defined in this contract: PileOuFace and ResultatDuJet. Enums are used to create user-defined data types with a finite set of values.

PileOuFace has two values: PILE and FACE, representing the two sides of a coin.
ResultatDuJet also has two values: GAGNE and PERDU, representing the possible outcomes of the coin flip.
Event Declaration: An event named Result is declared. Events are used to log important contract state changes that can be observed by external applications and users. This event has three indexed parameters:

address indexed joueur: The address of the joueur who initiated the coin flip.
PileOuFace coteChoisi: The side of the coin chosen by the joueur.
ResultatDuJet resultat: The resultat of the coin flip (GAGNE or PERDU).
Function jetDePiece: This is the main function of the contract that allows a joueur to flip the coin by specifying their chosen side (coteChoisi).

Inside the function, a random number is generated using keccak256 hashing. The input to this hash function is the concatenation of block.timestamp (the current timestamp) and msg.sender (the address of the transaction sender).

The resultat of this hash operation is a hexadecimal number, but it's converted to a uint256 type using uint256().

The modulo operator % 2 is used to limit the resultat to either 0 or 1, effectively simulating the random outcome of a coin flip.

The random number is then converted to a PileOuFace enum value (PILE or FACE) and stored in the resultat variable.

The code then checks if the coteChoisi by the joueur is the same as the generated resultat. If they match, the resultatDuJet is set to GAGNE, indicating that the joueur has won; otherwise, it's set to PERDU.

Finally, an emit statement is used to log the resultat of the coin flip by triggering the Result event with the joueur's address, the side they chose, and the outcome of the flip.

In summary, this Solidity contract allows users to play a simple coin flipping game. When a joueur calls the jetDePiece function and chooses a side, the contract generates a random outcome and emits an event to log the resultat, indicating whether the joueur has won or lost based on their choice.

*/
