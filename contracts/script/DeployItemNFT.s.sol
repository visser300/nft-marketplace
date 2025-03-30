// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ItemNFT} from "../src/ItemNFT.sol";

contract DeployItemNFT is Script {
    function run() external returns (ItemNFT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the ItemNFT contract
        ItemNFT itemNFT = new ItemNFT();
        
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("ItemNFT deployed at:", address(itemNFT));
        
        return itemNFT;
    }
} 