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

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo -e "${RED}Error: ETHERSCAN_API_KEY environment variable is not set.${NC}"
    exit 1
fi

# Deploy the ItemNFT contract
echo -e "${YELLOW}Deploying ItemNFT contract...${NC}"
forge script script/DeployItemNFT.s.sol:DeployItemNFT \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --ffi \
    -vvv

if [ $? -eq 0 ]; then
    echo -e "${GREEN}ItemNFT contract deployed successfully!${NC}"
    echo -e "${YELLOW}Don't forget to set ITEM_NFT_ADDRESS in your .env file for MarketPlace deployment${NC}"
else
    echo -e "${RED}Failed to deploy ItemNFT contract.${NC}"
    exit 1
fi

echo -e "${GREEN}Done!${NC}" 