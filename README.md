# Durin NFT Contracts

These contracts, developed with Unruggable, allow you to issue NFT subnames on an L2 network. Follow the steps below to set up and deploy the contracts.

## Prerequisites

Ensure [Foundry](https://book.getfoundry.sh/getting-started/installation) is installed.

## Setup and Deployment

1. **Clone the repository**

   ```shell
   git clone git@github.com:resolverworks/durin-nft-contracts.git
   cd durin-nft-contracts
   ```

2. **Set up environment variables**

   Copy `example.env` to `.env` and update the following values:

   ```env
   # NFTRegistry contract deployment
   RPC_URL=https://your-rpc-url-here
   ETHERSCAN_API_KEY=your-etherscan-api-key
   PRIVATE_KEY=your-private-key-here
   BASE_URI=https://your-base-uri.com/nft/
   CONTRACT_SYMBOL=your-contract-symbol-here
   ```

   - RPC_URL: RPC endpoint for your L2 (e.g., Alchemy or Infura)
   - ETHERSCAN_API_KEY: For contract verification (available from your L2's block explorer)
   - PRIVATE_KEY: The private key to you wallet with enough L2 funds to deploy contracts
   - BASE_URI: URL for your NFT metadata (modifiable later via setBaseURI)
   - CONTRACT_SYMBOL: Symbol for your NFT collection

3. **Deploy NFTRegistry contract**

   ```shell
   bash deploy/deployNFTRegistry.sh
   ```

   Take note of the deployed contract address.

4. **Update .env for NFTRegistrar deployment**

   Update the following values on your `.env` file:

   ```env
   # NFTRegistrar contract deployment
   REGISTRY_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   Explanations:

   - `REGISTRY_ADDRESS`: Address of the NFTRegistry contract

5. **Deploy NFTRegistrar contract**

   ```shell
   bash deploy/deployNFTRegistrar.sh
   ```

   Note the deployed contract address.

6. **Set parameters and grant permissions on your deployed contracts**

   Update the Registrar address and parameter values in your `.env`:

   ```env
   # Set Parameters and grant permission
   REGISTRAR_ADDRESS=0x1234567890123456789012345678901234567890
   NAME_PRICE=0
   ```

   Then run:

   ```shell
   bash deploy/setParameters.sh
   ```

   This grants the Registrar the ability to mint names on the Registry and sets pricing and name limits.

   Explanations:

   - `NAME_PRICE`: Pricing for a name in USD.

   Note: These parameters can be modified later via the contract on your L2 blockexplorer.

7. **Connect base name to resolver and registry**

   (Instructions coming soon)

## Usage

You can now mint names via the Registrar. Check out our example frontend or build your own.

## Deploy NFTRegistryFactory

1. **Set up environment variables**

   Change your env to reflect the chain you want to deploy on

   ```env
   # NFTRegistry contract deployment
   RPC_URL=https://your-rpc-url-here
   ETHERSCAN_API_KEY=your-etherscan-api-key
   ```

   and set your salt if you haven't

   ```env
   # Deploy NFTRegistryFactory contract
   SALT="my_salt"
   ```

````

2. **Run deploy script **

 ```shell
   bash deploy/DeployNFTRegistryFactory.sh
````

alter your env for each chain you release on. As long as you don't change your salt they will all have the same address

3. ** Deploy Registry using Factory**!SECTION
   add your factory address to your env

   ```env
   # Deploy NFTRegistryFactory contract
   FACTORY_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   Run the bash script to deploy a registry

   ```bash
   bash deploy/DeployNFTRegistryWithFactory.sh
   ```
