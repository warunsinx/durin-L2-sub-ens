#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$REGISTRY_ADDRESS" ] || \
   [ -z "$REGISTRAR_ADDRESS" ] || \
   [ -z "$MIN_REGISTRATION_DURATION" ] || [ -z "$MAX_REGISTRATION_DURATION" ] || \
   [ -z "$MIN_CHARS" ] || [ -z "$MAX_CHARS" ] || [ -z "$MAX_FREE_REGISTRATIONS" ] || \
   [ -z "$CHAR_AMOUNTS" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set contract details
CONTRACT_NAME="NFTRegistry"
FUNCTION_SIGNATURE="addRegistrar(address)"

echo "Granting REGISTRAR_ROLE to the Registrar..."
cast send $REGISTRY_ADDRESS \
    "$FUNCTION_SIGNATURE" \
    $REGISTRAR_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Set register parameters
echo "Setting register parameters..."
cast send $REGISTRAR_ADDRESS \
    "setParams(uint256,uint256,uint16,uint16)" \
    $MIN_REGISTRATION_DURATION $MAX_REGISTRATION_DURATION $MIN_CHARS $MAX_CHARS \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY

echo "Setting name pricing..."
FORMATTED_AMOUNTS=$(echo $CHAR_AMOUNTS | sed 's/ /,/g')
echo $FORMATTED_AMOUNTS
cast send $REGISTRAR_ADDRESS \
    "setPricingForAllLengths(uint256[])" \
    "$CHAR_AMOUNTS" \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Set max free registrations
echo "Setting max free registrations..."
cast send $REGISTRAR_ADDRESS \
    "setMaxFreeRegistrations(uint256)" \
    $MAX_FREE_REGISTRATIONS \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY