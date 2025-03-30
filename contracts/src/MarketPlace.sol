// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./ItemNFT.sol";

contract MarketPlace is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct TokenInfo {
        uint256 tokenId;
    }

    // The only NFT contract allowed to interact with this marketplace
    ItemNFT public itemNFT;
    
    mapping(bytes32 => address) private tokenOwners;
    mapping(address => TokenInfo[]) private userTokens;

    event TokenAdded(address indexed user, uint256 tokenId);
    event TokenRemoved(address indexed user, uint256 tokenId);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /// @notice Initializes the contract
    function initialize(address _itemNFTAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        // Set the ItemNFT contract address
        itemNFT = ItemNFT(_itemNFTAddress);
    }
    
    function _getTokenHash(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId));
    }

    function addUserToken(address user, uint256 tokenId) public onlyOwner {
        // Verify the token exists in the ItemNFT contract
        require(itemNFT.ownerOf(tokenId) == user, "User is not the owner of this token");
        
        bytes32 tokenHash = _getTokenHash(tokenId);
        tokenOwners[tokenHash] = user;
        
        TokenInfo memory newToken = TokenInfo(tokenId);
        userTokens[user].push(newToken);
        emit TokenAdded(user, tokenId);
    }

    function removeOwnership(address user, uint256 tokenId) public onlyOwner {
        removeTokenOwner(tokenId);
        removeUserToken(user, tokenId);
        emit TokenRemoved(user, tokenId);
    }

    function removeTokenOwner(uint256 tokenId) private {
        bytes32 tokenHash = _getTokenHash(tokenId);
        tokenOwners[tokenHash] = address(0);
    }
    
    function removeUserToken(address user, uint256 tokenId) private {
        for (uint256 i = 0; i < userTokens[user].length; i++) {
            if (userTokens[user][i].tokenId == tokenId) {
                delete userTokens[user][i];
                emit TokenRemoved(user, tokenId);
                return;
            }
        }
    }
    
    function getTokenOwner(uint256 tokenId) public view returns (address) {
        bytes32 tokenHash = _getTokenHash(tokenId);
        return tokenOwners[tokenHash];
    }

    function getUserTokens(address user) public view returns (TokenInfo[] memory) {
        return userTokens[user];
    }

    // Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // This function is inherited from UUPSUpgradeable but needs to be exposed
    function upgradeTo(address newImplementation) public onlyOwner {
        _authorizeUpgrade(newImplementation);
        upgradeToAndCall(newImplementation, new bytes(0));
    }
} 