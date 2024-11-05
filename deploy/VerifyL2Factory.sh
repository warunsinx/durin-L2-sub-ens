#!/bin/bash

# Load environment variables
source .env

# Get the deployed contract address (you should save this after deployment)
FACTORY_ADDRESS="${FACTORY_ADDRESS}"

# Get your chain's Etherscan API key from env
ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY}"

# Verify on desired network (update network name as needed)
# Examples: arbitrum, optimism, base, etc.
NETWORK="optimism"

# Run verification
echo "Verifying contract..."
forge verify-contract \
    --chain "${NETWORK}" \
    --etherscan-api-key "${ETHERSCAN_API_KEY}" \
    --watch \
    --constructor-args $(cast abi-encode "constructor()") \
    "${FACTORY_ADDRESS}" \
    src/L2RegistryFactory.sol:L2RegistryFactory


# Check verification status
echo "Verification submitted. Check status on the block explorer."