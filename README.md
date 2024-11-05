# ENS Subnames on L2

There is no official way to build ENS subnames on L2, but this repo implements one possible approach.

## Archicture

ENS resolution always starts on L1, so we use [CCIP Read](https://eips.ethereum.org/EIPS/eip-3668) to defer the resolution to L2. We include the target L2 registry info in the offchain lookup, which is stored in the L1 resolver contract, so the gateway knows where to forward the request.

Since we cannot easily determine the ownership of a L1 .eth name (e.g., name.eth) from L2, we allow anyone to create a registry on L2 via a factory contract. This means multiple L2 registries can exist for the same .eth name. This is acceptable because only the owner of the .eth name on L1 can set the target L2 registry for that name, making it canonical.

![diagram](https://github.com/user-attachments/assets/528cf959-82e7-4d1b-8574-3c5de942af97)

## Contracts

This repo includes the L2 registry contracts.

- [L2RegistryFactory](./src/L2RegistryFactory.sol): L2 contract for easily creating new registries.
- [L2Registry](./src/L2Registry.sol): L2 contract that stores subnames as ERC721 NFTs.
  It's responsible for storing subname data like address and text records.
- [L2Registrar](./src/L2Registrar.sol): L2 contract that has access to register names to the L2Registry. It's a separate contract because it's most likely to be customized, and you may want to have multiple registrars for the same registry.

## Deploy Registrar

Below are the steps to deploy the registrar.
The other steps to deploy L2 subnames can be found on [our frontend site] Or Manual setup readme

1. **Clone the repository**

   ```shell
   git clone git@github.com:resolverworks/durin-nft-contracts.git
   cd durin-nft-contracts
   ```

2. **Set up environment variables**

   Copy `example.env` to `.env` and update the following values:

   ```env
   # Required to Deploy Any Contract
   RPC_URL=https://your-rpc-url-here
   PRIVATE_KEY=your-private-key-here
   BASE_URI=https://your-base-uri.com/
   ETHERSCAN_API_KEY=your-etherscan-api-key-here
   CONTRACT_SYMBOL=your-contract-symbol-here

   # Required to Deploy L2Registrar contract
   REGISTRY_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   - RPC_URL: RPC endpoint for your L2 (e.g., Alchemy or Infura)
   - ETHERSCAN_API_KEY: For contract verification (available from your L2's block explorer)
   - PRIVATE_KEY: The private key to you wallet with enough L2 funds to deploy contracts
   - BASE_URI: URL for your NFT metadata (modifiable later via setBaseURI)
   - CONTRACT_SYMBOL: Symbol for your NFT collection
   - `REGISTRY_ADDRESS`: Address of the L2Registry contract

3. **Deploy L2Registrar contract**

   ```shell
   bash deploy/deployL2Registrar.sh
   ```

   Note the deployed contract address.

4. **Set parameters and grant permissions on your deployed contracts**

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
