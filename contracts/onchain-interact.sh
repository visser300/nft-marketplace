#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    echo -e "${YELLOW}Loading environment variables...${NC}"
    source .env
else
    echo -e "${RED}Error: .env file not found. Please create one with the required variables.${NC}"
    exit 1
fi

# Check required environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set.${NC}"
    exit 1
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Error: SEPOLIA_RPC_URL environment variable is not set.${NC}"
    exit 1
fi

if [ -z "$ITEM_NFT_ADDRESS" ]; then
    echo -e "${RED}Error: ITEM_NFT_ADDRESS environment variable is not set.${NC}"
    exit 1
fi

if [ -z "$MARKETPLACE_PROXY_ADDRESS" ]; then
    echo -e "${RED}Error: MARKETPLACE_PROXY_ADDRESS environment variable is not set.${NC}"
    exit 1
fi

# Function to mint a new NFT
mint_nft() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing arguments for mint_nft.${NC}"
        echo -e "${YELLOW}Usage: ./interact.sh mint <recipient_address> <token_uri>${NC}"
        exit 1
    fi
    
    RECIPIENT=$1
    TOKEN_URI=$2
    
    echo -e "${YELLOW}Minting NFT to ${RECIPIENT} with URI ${TOKEN_URI}...${NC}"
    forge script script/InteractWithContracts.s.sol:InteractWithContracts \
        --sig "mintNFT(address,address,string)(uint256)" \
        $ITEM_NFT_ADDRESS $RECIPIENT "$TOKEN_URI" \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast
}

# Function to add a token to the marketplace
add_token() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing arguments for add_token.${NC}"
        echo -e "${YELLOW}Usage: ./interact.sh add <user_address> <token_id>${NC}"
        exit 1
    fi
    
    USER=$1
    TOKEN_ID=$2
    
    echo -e "${YELLOW}Adding token ${TOKEN_ID} to marketplace for user ${USER}...${NC}"
    forge script script/InteractWithContracts.s.sol:InteractWithContracts \
        --sig "addTokenToMarketplace(address,address,uint256)" \
        $MARKETPLACE_PROXY_ADDRESS $USER $TOKEN_ID \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast
}

# Function to get token owner from marketplace
get_token_owner() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Missing token ID for get_token_owner.${NC}"
        echo -e "${YELLOW}Usage: ./interact.sh owner <token_id>${NC}"
        exit 1
    fi
    
    TOKEN_ID=$1
    
    echo -e "${YELLOW}Getting owner of token ${TOKEN_ID}...${NC}"
    forge script script/InteractWithContracts.s.sol:InteractWithContracts \
        --sig "getTokenOwner(address,uint256)(address)" \
        $MARKETPLACE_PROXY_ADDRESS $TOKEN_ID \
        --rpc-url $SEPOLIA_RPC_URL
}

# Function to get all tokens for a user
get_user_tokens() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Missing user address for get_user_tokens.${NC}"
        echo -e "${YELLOW}Usage: ./interact.sh tokens <user_address>${NC}"
        exit 1
    fi
    
    USER=$1
    
    echo -e "${YELLOW}Getting tokens for user ${USER}...${NC}"
    forge script script/InteractWithContracts.s.sol:InteractWithContracts \
        --sig "getUserTokens(address,address)" \
        $MARKETPLACE_PROXY_ADDRESS $USER \
        --rpc-url $SEPOLIA_RPC_URL
}

# Function to remove a token from the marketplace
remove_token() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing arguments for remove_token.${NC}"
        echo -e "${YELLOW}Usage: ./interact.sh remove <user_address> <token_id>${NC}"
        exit 1
    fi
    
    USER=$1
    TOKEN_ID=$2
    
    echo -e "${YELLOW}Removing token ${TOKEN_ID} from marketplace for user ${USER}...${NC}"
    forge script script/InteractWithContracts.s.sol:InteractWithContracts \
        --sig "removeTokenFromMarketplace(address,address,uint256)" \
        $MARKETPLACE_PROXY_ADDRESS $USER $TOKEN_ID \
        --rpc-url $SEPOLIA_RPC_URL \
        --broadcast
}

# Main script
case "$1" in
    mint)
        mint_nft "$2" "$3"
        ;;
    add)
        add_token "$2" "$3"
        ;;
    owner)
        get_token_owner "$2"
        ;;
    tokens)
        get_user_tokens "$2"
        ;;
    remove)
        remove_token "$2" "$3"
        ;;
    *)
        echo -e "${YELLOW}Usage:${NC}"
        echo -e "  ${GREEN}./interact.sh mint <recipient_address> <token_uri>${NC} - Mint a new NFT"
        echo -e "  ${GREEN}./interact.sh add <user_address> <token_id>${NC} - Add a token to the marketplace"
        echo -e "  ${GREEN}./interact.sh owner <token_id>${NC} - Get the owner of a token"
        echo -e "  ${GREEN}./interact.sh tokens <user_address>${NC} - Get all tokens for a user"
        echo -e "  ${GREEN}./interact.sh remove <user_address> <token_id>${NC} - Remove a token from the marketplace"
        exit 1
        ;;
esac

echo -e "${GREEN}Done!${NC}"