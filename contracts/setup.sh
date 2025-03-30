#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Foundry project setup...${NC}"

# Clean up existing dependencies and lib directory
echo -e "${YELLOW}Cleaning up existing dependencies...${NC}"
if [ -d "lib" ]; then
    rm -rf lib
    echo -e "${GREEN}Removed lib directory${NC}"
fi

# Install Foundry if not already installed
if ! command -v forge &> /dev/null
then
    echo -e "${YELLOW}Installing Foundry...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source $HOME/.bashrc
    foundryup
fi

# Initialize Foundry project if not already initialized
if [ ! -f "foundry.toml" ]; then
    echo -e "${YELLOW}Initializing Foundry project...${NC}"
    forge init --no-commit
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
forge install foundry-rs/forge-std --no-commit

# Install OpenZeppelin dependencies
echo -e "${YELLOW}Installing OpenZeppelin dependencies...${NC}"
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# Create or update remappings.txt
echo -e "${YELLOW}Creating/updating remappings.txt...${NC}"
echo "forge-std/=lib/forge-std/src/" > remappings.txt
echo "@openzeppelin/=lib/openzeppelin-contracts/" >> remappings.txt
echo "@openzeppelin-upgradeable/=lib/openzeppelin-contracts-upgradeable/" >> remappings.txt
echo -e "${GREEN}Updated remappings.txt${NC}"

# Create .env file from example if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo -e "${YELLOW}Creating .env file from example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Don't forget to update your .env file with your own values!${NC}"
fi

# Build the project
echo -e "${YELLOW}Building the project...${NC}"
forge build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
    
    # Run tests
    echo -e "${YELLOW}Running tests...${NC}"
    forge test
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
    else
        echo -e "${RED}Some tests failed. Please check the output above.${NC}"
    fi
else
    echo -e "${RED}Build failed. Please check the output above.${NC}"
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}Here are some useful commands:${NC}"
echo -e "  ${GREEN}forge test${NC} - Run tests"
echo -e "  ${GREEN}forge build${NC} - Build the project"
echo -e "  ${GREEN}forge script script/DeployMarketPlace.s.sol:DeployMarketPlace --rpc-url \$SEPOLIA_RPC_URL --private-key \$PRIVATE_KEY --broadcast${NC} - Deploy to Sepolia"

echo -e "\n${YELLOW}To deploy to Sepolia:${NC}"
echo -e "1. Make sure your .env file is properly configured"
echo -e "2. Run: ${GREEN}source .env${NC}"
echo -e "3. Run: ${GREEN}forge script script/DeployMarketPlace.s.sol:DeployMarketPlace --rpc-url \$SEPOLIA_RPC_URL --private-key \$PRIVATE_KEY --broadcast${NC}" 