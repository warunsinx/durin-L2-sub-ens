#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$ETHERSCAN_API_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Build the project
echo "Building the project..."
forge build

# Deploy using
DEPLOYED_OUTPUT=$(forge script deploy/FactoryDeployer.sol:FactoryDeployer --rpc-url $RPC_URL --broadcast)

echo "$DEPLOYED_OUTPUT"
