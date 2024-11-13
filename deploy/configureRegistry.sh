#!/bin/bash

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$REGISTRY_ADDRESS" ] || \
   [ -z "$REGISTRAR_ADDRESS" ] || \
   [ -z $"NAME_PRICE" ]; then
    echo "Error: Missing required environment variables. Please check your .env file."
    exit 1
fi

# Set Registrar Role on Registry 
echo "Granting REGISTRAR_ROLE to the Registrar..."
cast send $REGISTRY_ADDRESS \
    "addRegistrar(address)" \
    "$REGISTRAR_ADDRESS" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Set registrar parameters
echo "Setting price..."
FORMATTED_AMOUNTS=$(echo $CHAR_AMOUNTS | sed 's/ /,/g')
echo $FORMATTED_AMOUNTS
cast send $REGISTRAR_ADDRESS \
    "setPrice(uint256)" \
    "$NAME_PRICE" \
    --rpc-url $RPC_URL --private-key $PRIVATE_KEY


echo "All parameters set successfully!"