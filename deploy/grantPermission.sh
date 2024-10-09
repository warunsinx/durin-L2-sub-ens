#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$REGISTRY_ADDRESS" ] || \
   [ -z "$REGISTRAR_ADDRESS" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set contract details
CONTRACT_NAME="NFTRegistry"
FUNCTION_SIGNATURE="addRegistrar(address)"

echo "Granting REGISTRAR_ROLE to the Registrar..."
forge send $REGISTRY_ADDRESS \
    "$FUNCTION_SIGNATURE" \
    $REGISTRAR_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Check if the transaction was successful
if [ $? -eq 0 ]; then
    echo "Permission granted successfully!"
    echo "Registrar address $REGISTRAR_ADDRESS now has REGISTRAR_ROLE on Registry $REGISTRY_ADDRESS"
else
    echo "Failed to grant permission. Please check the error messages above."
    exit 1
fi