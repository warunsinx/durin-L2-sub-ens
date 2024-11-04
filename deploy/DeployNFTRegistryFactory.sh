#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Error: ETHERSCAN_API_KEY is not set"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "Error: RPC_URL is not set"
    exit 1
fi



if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY is not set"
    exit 1
fi

# Print deployment configuration
echo "Deployment Configuration:"
echo "- Ethereum RPC URL is set: ✓"
echo "- Private Key is set: ✓"
echo "- Etherscan API Key is set: ✓"

# Build the project
echo "Building the project..."
forge build --force

# Deploy with verbose output
echo "Deploying contracts..."
forge script deploy/FactoryDeployer.sol:FactoryDeployer \
    --rpc-url $RPC_URL \
    --broadcast \
    -vvvv