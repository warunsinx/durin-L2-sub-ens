# Durin L2 Contracts

These contracts, developed with Unruggable, allow you to issue L2 subnames on an L2 network. Follow the steps below to set up and deploy the L2 Subnames manually.

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
   # L2Registry contract deployment
   RPC_URL=https://your-rpc-url-here
   ETHERSCAN_API_KEY=your-etherscan-api-key
   PRIVATE_KEY=your-private-key-here
   BASE_URI=https://your-base-uri.com/L2/
   CONTRACT_SYMBOL=your-contract-symbol-here
   ```

   - RPC_URL: RPC endpoint for your L2 (e.g., Alchemy or Infura)
   - ETHERSCAN_API_KEY: For contract verification (available from your L2's block explorer)
   - PRIVATE_KEY: The private key to you wallet with enough L2 funds to deploy contracts
   - BASE_URI: URL for your NFT metadata (modifiable later via setBaseURI)
   - CONTRACT_SYMBOL: Symbol for your NFT collection

3. **Deploy L2Registry contract**

   ```shell
   bash deploy/deployL2Registry.sh
   ```

   Take note of the deployed contract address.

4. **Update .env for L2Registrar deployment**

   Update the following values on your `.env` file:

   ```env
   # L2Registrar contract deployment
   REGISTRY_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   Explanations:

   - `REGISTRY_ADDRESS`: Address of the L2Registry contract

5. **Deploy L2Registrar contract**

   ```shell
   bash deploy/deployL2Registrar.sh
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

## Deploy L2RegistryFactory

1. **Set up environment variables**

   Change your env to reflect the chain you want to deploy on

   ```env
   # L2Registry contract deployment
   RPC_URL=https://your-rpc-url-here
   ETHERSCAN_API_KEY=your-etherscan-api-key
   ```

   and set your salt if you haven't

   ```env
   # Deploy L2RegistryFactory contract
   SALT="my_salt"
   ```

````

2. **Run deploy script **

 ```shell
   bash deploy/DeployL2RegistryFactory.sh
````

alter your env for each chain you release on. As long as you don't change your salt they will all have the same address

3. ** Deploy Registry using Factory**!SECTION
   add your factory address to your env

   ```env
   # Deploy L2RegistryFactory contract
   FACTORY_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   Run the bash script to deploy a registry

   ```bash
   bash deploy/DeployL2RegistryWithFactory.sh
   ```
