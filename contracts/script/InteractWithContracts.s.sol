// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ItemNFT} from "../src/ItemNFT.sol";
import {MarketPlace} from "../src/MarketPlace.sol";

contract InteractWithContracts is Script {
    // Function to mint a new NFT
    function mintNFT(address itemNFTAddress, address recipient, string memory tokenURI) public returns (uint256) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ItemNFT itemNFT = ItemNFT(itemNFTAddress);
        uint256 tokenId = itemNFT.safeMint(recipient, tokenURI);
        
        vm.stopBroadcast();
        
        console.log("Minted NFT with token ID:", tokenId);
        console.log("Owner:", recipient);
        console.log("Token URI:", tokenURI);
        
        return tokenId;
    }
}