#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$ETHERSCAN_API_KEY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$REGISTRY_ADDRESS" ] || \
   [ -z "$MIN_COMMITMENT_AGE" ] || [ -z "$MAX_COMMITMENT_AGE" ] || [ -z "$USD_ORACLE_ADDRESS" ] || \
   [ -z "$MIN_REGISTRATION_DURATION" ] || [ -z "$MAX_REGISTRATION_DURATION" ] || \
   [ -z "$MIN_CHARS" ] || [ -z "$MAX_CHARS" ] || [ -z "$MAX_FREE_REGISTRATIONS" ] || \
   [ -z "$CHAR_AMOUNTS" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set contract details
CONTRACT_NAME="NFTRegistrar"
CONTRACT_FILE="src/NFTRegistrar.sol"

# Build the project
echo "Building the project..."
forge build

# Deploy the contract
echo "Deploying $CONTRACT_NAME from $CONTRACT_FILE..."
DEPLOYED_ADDRESS=$(ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY forge create --rpc-url $RPC_URL \
             --private-key $PRIVATE_KEY \
	      --verify \
	      --legacy \
             $CONTRACT_FILE:$CONTRACT_NAME \
             --constructor-args $REGISTRY_ADDRESS $MIN_COMMITMENT_AGE $MAX_COMMITMENT_AGE $USD_ORACLE_ADDRESS \
             --json | jq -r '.deployedTo')

# Check deployment status
if [ -z "$DEPLOYED_ADDRESS" ]; then
    echo "Deployment failed. Please check the error messages above."
    exit 1
else
    echo "$CONTRACT_NAME deployed successfully at address: $DEPLOYED_ADDRESS"
fi

# Set pricing parameters
echo "Setting pricing parameters..."
forge send $DEPLOYED_ADDRESS \
    "setParams(uint64,uint64,uint16,uint16)" \
    $MIN_REGISTRATION_DURATION $MAX_REGISTRATION_DURATION $MIN_CHARS $MAX_CHARS \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Set character amounts
echo "Setting character amounts..."
forge send $DEPLOYED_ADDRESS \
    "setPricingForAllLengths(uint256[])" \
    "[${CHAR_AMOUNTS}]" \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Set max free registrations
echo "Setting max free registrations..."
forge send $DEPLOYED_ADDRESS \
    "setMaxFreeRegistrations(uint256)" \
    $MAX_FREE_REGISTRATIONS \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY

echo "All parameters set successfully!"