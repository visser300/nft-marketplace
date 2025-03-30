// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {ItemNFT} from "../src/ItemNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract MarketPlaceTest is Test {
    MarketPlace public implementation;
    MarketPlace public marketPlace;
    ItemNFT public itemNFT;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    string public constant TOKEN_URI = "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG";
    
    function setUp() public {
        // Deploy ItemNFT first
        vm.startPrank(owner);
        itemNFT = new ItemNFT();
        
        // Deploy implementation
        implementation = new MarketPlace();
        
        // Deploy proxy with implementation
        bytes memory initData = abi.encodeWithSelector(
            MarketPlace.initialize.selector,
            address(itemNFT)
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        // Get the proxy as a MarketPlace
        marketPlace = MarketPlace(address(proxy));
        vm.stopPrank();
    }
    
    // Test initialization
    function testInitialization() public view {
        assertEq(marketPlace.owner(), owner);
        assertEq(address(marketPlace.itemNFT()), address(itemNFT));
    }
    
    // Test adding a token
    function testAddUserToken() public {
        // First mint a token to user1
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        
        // Then add it to the marketplace
        marketPlace.addUserToken(user1, tokenId);
        vm.stopPrank();
        
        assertEq(marketPlace.getTokenOwner(tokenId), user1);
        
        MarketPlace.TokenInfo[] memory tokens = marketPlace.getUserTokens(user1);
        assertEq(tokens.length, 1);
        assertEq(tokens[0].tokenId, tokenId);
    }
    
    // Test adding multiple tokens
    function testAddMultipleTokens() public {
        vm.startPrank(owner);
        uint256 tokenId1 = itemNFT.safeMint(user1, TOKEN_URI);
        uint256 tokenId2 = itemNFT.safeMint(user1, TOKEN_URI);
        uint256 tokenId3 = itemNFT.safeMint(user1, TOKEN_URI);
        
        marketPlace.addUserToken(user1, tokenId1);
        marketPlace.addUserToken(user1, tokenId2);
        marketPlace.addUserToken(user1, tokenId3);
        vm.stopPrank();
        
        MarketPlace.TokenInfo[] memory tokens = marketPlace.getUserTokens(user1);
        assertEq(tokens.length, 3);
    }
    
    // Test removing ownership
    function testRemoveOwnership() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        marketPlace.addUserToken(user1, tokenId);
        marketPlace.removeOwnership(user1, tokenId);
        vm.stopPrank();
        
        assertEq(marketPlace.getTokenOwner(tokenId), address(0));
    }
    
    // Test removing a token that doesn't exist
    function testRemoveNonExistentToken() public {
        vm.startPrank(owner);
        // This should not revert, just do nothing
        marketPlace.removeOwnership(user1, 999);
        vm.stopPrank();
    }
    
    // Test access control - only owner can add tokens
    function testOnlyOwnerCanAddTokens() public {
        // First mint a token to user1
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user1)
        );
        marketPlace.addUserToken(user1, tokenId);
        vm.stopPrank();
    }
    
    // Test access control - only owner can remove tokens
    function testOnlyOwnerCanRemoveTokens() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        marketPlace.addUserToken(user1, tokenId);
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user1)
        );
        marketPlace.removeOwnership(user1, tokenId);
        vm.stopPrank();
    }
    
    // Test getting tokens for a user with no tokens
    function testGetTokensForEmptyUser() public view {
        MarketPlace.TokenInfo[] memory tokens = marketPlace.getUserTokens(user2);
        assertEq(tokens.length, 0);
    }
    
    // Test token hash generation (indirectly)
    function testTokenHashGeneration() public {
        vm.startPrank(owner);
        uint256 tokenId1 = itemNFT.safeMint(user1, TOKEN_URI);
        uint256 tokenId2 = itemNFT.safeMint(user2, TOKEN_URI);
        
        marketPlace.addUserToken(user1, tokenId1);
        marketPlace.addUserToken(user2, tokenId2);
        vm.stopPrank();
        
        assertEq(marketPlace.getTokenOwner(tokenId1), user1);
        assertEq(marketPlace.getTokenOwner(tokenId2), user2);
        // Different tokens should have different owners
        assertTrue(marketPlace.getTokenOwner(tokenId1) != marketPlace.getTokenOwner(tokenId2));
    }
    
    // Test that user must own the token to add it
    function testUserMustOwnToken() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        
        // Try to add the token to user2 (who doesn't own it)
        vm.expectRevert("User is not the owner of this token");
        marketPlace.addUserToken(user2, tokenId);
        vm.stopPrank();
    }
    
    // Test upgradeability
    function testUpgrade() public {
        // Deploy new implementation
        vm.startPrank(owner);
        MarketPlace newImplementation = new MarketPlace();
        
        // Upgrade
        marketPlace.upgradeTo(address(newImplementation));
        vm.stopPrank();
        
        // Functionality should still work after upgrade
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        marketPlace.addUserToken(user1, tokenId);
        vm.stopPrank();
        
        assertEq(marketPlace.getTokenOwner(tokenId), user1);
    }
    
    // Test that non-owners cannot upgrade
    function testOnlyOwnerCanUpgrade() public {
        vm.startPrank(user1);
        MarketPlace newImplementation = new MarketPlace();
        
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user1)
        );
        marketPlace.upgradeTo(address(newImplementation));
        vm.stopPrank();
    }
    
    // Test events
    function testTokenAddedEvent() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        
        vm.expectEmit(true, false, false, true);
        emit MarketPlace.TokenAdded(user1, tokenId);
        marketPlace.addUserToken(user1, tokenId);
        vm.stopPrank();
    }
    
    function testTokenRemovedEvent() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        marketPlace.addUserToken(user1, tokenId);
        
        vm.expectEmit(true, false, false, true);
        emit MarketPlace.TokenRemoved(user1, tokenId);
        marketPlace.removeOwnership(user1, tokenId);
        vm.stopPrank();
    }
    
    // Test removing a token from a user's list
    function testRemoveUserToken() public {
        vm.startPrank(owner);
        uint256 tokenId1 = itemNFT.safeMint(user1, TOKEN_URI);
        uint256 tokenId2 = itemNFT.safeMint(user1, TOKEN_URI);
        
        marketPlace.addUserToken(user1, tokenId1);
        marketPlace.addUserToken(user1, tokenId2);
        marketPlace.removeOwnership(user1, tokenId1);
        vm.stopPrank();
        
        // The token should be removed but the array length stays the same
        // with the element set to default values
        MarketPlace.TokenInfo[] memory tokens = marketPlace.getUserTokens(user1);
        assertEq(tokens.length, 2);
        assertEq(tokens[0].tokenId, 0); // Deleted element
        assertEq(tokens[1].tokenId, tokenId2); // Still exists
    }
} 