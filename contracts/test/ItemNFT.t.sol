// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ItemNFT} from "../src/ItemNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ItemNFTTest is Test {
    ItemNFT public itemNFT;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    string public constant TOKEN_URI = "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG";
    
    function setUp() public {
        vm.startPrank(owner);
        itemNFT = new ItemNFT();
        vm.stopPrank();
    }
    
    // Test initialization
    function testInitialization() public view {
        assertEq(itemNFT.name(), "Item NFT");
        assertEq(itemNFT.symbol(), "ITEM");
        assertEq(itemNFT.owner(), owner);
        assertEq(itemNFT.totalSupply(), 0);
    }
    
    // Test minting
    function testMint() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        assertEq(itemNFT.ownerOf(tokenId), user1);
        assertEq(itemNFT.tokenURI(tokenId), TOKEN_URI);
        assertEq(itemNFT.totalSupply(), 1);
    }
    
    // Test multiple mints
    function testMultipleMints() public {
        vm.startPrank(owner);
        uint256 tokenId1 = itemNFT.safeMint(user1, TOKEN_URI);
        uint256 tokenId2 = itemNFT.safeMint(user2, TOKEN_URI);
        vm.stopPrank();
        
        assertEq(itemNFT.ownerOf(tokenId1), user1);
        assertEq(itemNFT.ownerOf(tokenId2), user2);
        assertEq(itemNFT.totalSupply(), 2);
        assertEq(tokenId2, tokenId1 + 1);
    }
    
    // Test only owner can mint
    function testOnlyOwnerCanMint() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1)
        );
        itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
    }
    
    // Test token transfer
    function testTransfer() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        vm.startPrank(user1);
        itemNFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
        
        assertEq(itemNFT.ownerOf(tokenId), user2);
    }
    
    // Test approval and transfer
    function testApprovalAndTransfer() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        vm.startPrank(user1);
        itemNFT.approve(user2, tokenId);
        vm.stopPrank();
        
        vm.startPrank(user2);
        itemNFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
        
        assertEq(itemNFT.ownerOf(tokenId), user2);
    }
    
    // Test burning
    function testBurn() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        vm.startPrank(user1);
        itemNFT.burn(tokenId);
        vm.stopPrank();
        
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId)
        );
        itemNFT.ownerOf(tokenId);
    }
    
    // Test only owner or approved can burn
    function testOnlyOwnerOrApprovedCanBurn() public {
        vm.startPrank(owner);
        uint256 tokenId = itemNFT.safeMint(user1, TOKEN_URI);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectRevert("ItemNFT: caller is not owner nor approved");
        itemNFT.burn(tokenId);
        vm.stopPrank();
    }
    
    // Test supports interface
    function testSupportsInterface() public view {
        // ERC721 interface ID
        assertTrue(itemNFT.supportsInterface(0x80ac58cd));
        // ERC721Metadata interface ID
        assertTrue(itemNFT.supportsInterface(0x5b5e139f));
        // ERC165 interface ID
        assertTrue(itemNFT.supportsInterface(0x01ffc9a7));
    }
} 