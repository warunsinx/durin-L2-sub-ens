#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$ETHERSCAN_API_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [-z "$FACTORY_SALT"]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set contract details
FACTORY_NAME="NFTRegistryFactory"
FACTORY_FILE="src/NFTRegistryFactory.sol"

# Build the project
echo "Building the project..."
forge build

# Deploy the factory contract
echo "Deploying $FACTORY_NAME from $FACTORY_FILE..."
DEPLOYED_OUTPUT=$(ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY forge create --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    $FACTORY_FILE:$FACTORY_NAME \
    --verify \
    --legacy \
    --ast $FACTORY_SALT \
    --json)

# Save deployment info
echo "$DEPLOYED_OUTPUT"

# Extract and save the factory address
FACTORY_ADDRESS=$(echo "$DEPLOYED_OUTPUT" | jq -r '.deployedTo')
echo "FACTORY_ADDRESS=$FACTORY_ADDRESS" 