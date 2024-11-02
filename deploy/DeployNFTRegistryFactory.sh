#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$ETHERSCAN_API_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set contract details
FACTORY_NAME="NFTRegistryFactory"
FACTORY_FILE="src/NFTRegistryFactory.sol"

# Build the project
echo "Building the project..."
forge build

# Deploy using CREATE2
# --create2 flag tells forge to use CREATE2
# --salt flag specifies the salt for CREATE2 deployment
echo "Deploying $FACTORY_NAME using CREATE2..."
DEPLOYED_OUTPUT=$(ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY forge create --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    $FACTORY_FILE:$FACTORY_NAME \
    --verify \
    --create2 \
    --salt 0x0000000000000000000000000000000000000000000000000000000000000001 \
    --legacy \
    --json)

echo "$DEPLOYED_OUTPUT"

# Extract and display the deployed address
FACTORY_ADDRESS=$(echo $DEPLOYED_OUTPUT | jq -r .deployedTo)
echo "NFTRegistryFactory deployed to: $FACTORY_ADDRESS"