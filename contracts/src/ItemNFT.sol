// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ItemNFT
 * @dev A simple ERC721 token for storing items
 */
contract ItemNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    /**
     * @dev Constructor initializes the contract with a name and symbol
     */
    constructor() ERC721("Item NFT", "ITEM") Ownable(msg.sender) {}

    /**
     * @dev Mints a new token
     * @param to The address that will own the minted token
     * @param uri The token URI for metadata
     * @return The ID of the newly minted token
     */
    function safeMint(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    /**
     * @dev Burns a token
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()) || getApproved(tokenId) == _msgSender(),
            "ItemNFT: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev Returns the total number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    // The following functions are overrides required by Solidity

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
} 