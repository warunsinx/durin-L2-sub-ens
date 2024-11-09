# Durin

Durin is an opinionated approach to ENS L2 subnames. Durin consists:

1. Registry factory on supported chains
2. Registrar template
3. A default gateway server

| L2        | Registry Factory                                                                                                        |
| --------- | ----------------------------------------------------------------------------------------------------------------------- |
| Base      | [`0x903492091BC5B90f1cBd924089bcfd309b2c4Ea7`](https://basescan.org/address/0x903492091bc5b90f1cbd924089bcfd309b2c4ea7) |
| Optimism  | TBD                                                                                                                     |
| Scroll    | TBD                                                                                                                     |
| Arbitrium | TBD                                                                                                                     |
| linea     | TBD                                                                                                                     |

## Contracts

This repo includes the L2 contracts required to enable subname issuance.

- [L2RegistryFactory](./src/L2RegistryFactory.sol): L2 contract for creating new registries.
- [L2Registry](./src/L2Registry.sol): L2 contract that stores subnames as ERC721 NFTs.
  It's responsible for storing subname data like address and text records.
- [L2Registrar](./src/L2Registrar.sol): An example registrar contract that can mint subnames. This is meant to be customized.

# How To

## 1. Deploy Instance of Registry Factory

Durin.dev (coming soon) provides an a GUI to do this for you or you can call the [contract directly](https://basescan.org/address/0x903492091bc5b90f1cbd924089bcfd309b2c4ea7#writeContract).

## 2. Deploy Registrar (This is meant to be customized)

1. **Clone the repository**

   ```shell
   git clone git@github.com:resolverworks/durin-nft-contracts.git
   cd durin-nft-contracts
   ```

2. **Set up environment variables**

   Copy `example.env` to `.env` and update the following values:

   ```env
   # Required to Deploy Any Contract
   RPC_URL=
   PRIVATE_KEY=
   BASE_URI=
   ETHERSCAN_API_KEY=
   CONTRACT_SYMBOL=

   # Required to Deploy L2Registrar contract
   REGISTRY_ADDRESS=
   ```

3. **Deploy L2Registrar contract**

   ```shell
   bash deploy/deployL2Registrar.sh
   ```

   Note the deployed contract address.

4. **Configure deployed L2Registry**

   Approve the L2Registrar as a controller on your registry from step 1 via the `addRegistrar()` method. This grants the Registrar the ability to mint names on the Registry and can set pricing.

## Architecture

![diagram](https://github.com/user-attachments/assets/0ce15738-8689-4177-9efb-8bbc05d7404a)
