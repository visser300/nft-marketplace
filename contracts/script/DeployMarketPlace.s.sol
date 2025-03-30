// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMarketPlace is Script {
    function run() external returns (MarketPlace) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address itemNFTAddress = vm.envAddress("ITEM_NFT_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy implementation
        MarketPlace implementation = new MarketPlace();
        
        // Encode the initializer call with ItemNFT address
        bytes memory initData = abi.encodeWithSelector(
            MarketPlace.initialize.selector,
            itemNFTAddress
        );
        
        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        // Get the proxy as a MarketPlace
        MarketPlace marketPlace = MarketPlace(address(proxy));
        
        vm.stopBroadcast();
        
        // Log deployment information
        console.log("MarketPlace implementation deployed at:", address(implementation));
        console.log("MarketPlace proxy deployed at:", address(proxy));
        console.log("Using ItemNFT at:", itemNFTAddress);
        
        // Verify contracts
        if (block.chainid == 11155111) { // Sepolia chain ID
            _verifyContract(address(implementation), "MarketPlace");
            _verifyContract(address(proxy), "ERC1967Proxy", abi.encode(address(implementation), initData));
        }
        
        return marketPlace;
    }
    
    function _verifyContract(address contractAddress, string memory contractName) internal {
        string[] memory cmds = new string[](4);
        cmds[0] = "forge";
        cmds[1] = "verify-contract";
        cmds[2] = vm.toString(contractAddress);
        cmds[3] = contractName;
        vm.ffi(cmds);
    }
    
    function _verifyContract(address contractAddress, string memory contractName, bytes memory constructorArgs) internal {
        string[] memory cmds = new string[](6);
        cmds[0] = "forge";
        cmds[1] = "verify-contract";
        cmds[2] = vm.toString(contractAddress);
        cmds[3] = contractName;
        cmds[4] = "--constructor-args";
        cmds[5] = vm.toString(constructorArgs);
        vm.ffi(cmds);
    }
}

contract UpgradeMarketPlace is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("MARKETPLACE_PROXY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy new implementation
        MarketPlace newImplementation = new MarketPlace();
        
        // Get the proxy as a MarketPlace and upgrade
        MarketPlace marketPlace = MarketPlace(proxyAddress);
        marketPlace.upgradeTo(address(newImplementation));
        
        vm.stopBroadcast();
        
        // Log upgrade information
        console.log("New MarketPlace implementation deployed at:", address(newImplementation));
        console.log("MarketPlace proxy upgraded at:", proxyAddress);
        
        // Verify new implementation
        if (block.chainid == 11155111) { // Sepolia chain ID
            _verifyContract(address(newImplementation), "MarketPlace");
        }
    }
    
    function _verifyContract(address contractAddress, string memory contractName) internal {
        string[] memory cmds = new string[](4);
        cmds[0] = "forge";
        cmds[1] = "verify-contract";
        cmds[2] = vm.toString(contractAddress);
        cmds[3] = contractName;
        vm.ffi(cmds);
    }
} 