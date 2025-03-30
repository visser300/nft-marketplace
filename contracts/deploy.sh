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

# Function to deploy the MarketPlace contract
deploy_marketplace() {
    echo -e "${YELLOW}Deploying MarketPlace contract...${NC}"
    forge script script/DeployMarketPlace.s.sol:DeployMarketPlace \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --ffi \
        -vvv
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}MarketPlace contract deployed successfully!${NC}"
    else
        echo -e "${RED}Failed to deploy MarketPlace contract.${NC}"
        exit 1
    fi
}

# Function to upgrade the MarketPlace contract
upgrade_marketplace() {
    if [ -z "$MARKETPLACE_PROXY_ADDRESS" ]; then
        echo -e "${RED}Error: MARKETPLACE_PROXY_ADDRESS environment variable is not set.${NC}"
        echo -e "${YELLOW}Please set it to the address of the deployed proxy contract.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Upgrading MarketPlace contract...${NC}"
    forge script script/DeployMarketPlace.s.sol:UpgradeMarketPlace \
        --rpc-url $SEPOLIA_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --ffi \
        -vvv
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}MarketPlace contract upgraded successfully!${NC}"
    else
        echo -e "${RED}Failed to upgrade MarketPlace contract.${NC}"
        exit 1
    fi
}

# Main script
if [ "$1" == "deploy" ]; then
    deploy_marketplace
elif [ "$1" == "upgrade" ]; then
    upgrade_marketplace
else
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}./deploy.sh deploy${NC} - Deploy the MarketPlace contract"
    echo -e "  ${GREEN}./deploy.sh upgrade${NC} - Upgrade the MarketPlace contract"
    exit 1
fi

echo -e "${GREEN}Done!${NC}" 