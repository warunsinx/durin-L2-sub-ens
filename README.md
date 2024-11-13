# <img src="https://github.com/user-attachments/assets/4f01ef6e-3c1e-4201-83db-fac4b383a3b0" alt="durin" width="33%">

Durin is an opinionated approach to ENS L2 subnames. Durin consists of:

1. Registry factory on supported chains
2. Registrar template
3. A default gateway server

| L2        | Registry Factory                                                                                                                   |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Base      | [`0xFaE610A10e51A09fBa8621935632b9B6F6f0DC18`](https://basescan.org/address/0xfae610a10e51a09fba8621935632b9b6f6f0dc18)            |
| Optimism  | [`0xFaE610A10e51A09fBa8621935632b9B6F6f0DC18`](https://optimistic.etherscan.io/address/0xfae610a10e51a09fba8621935632b9b6f6f0dc18) |
| Scroll    | [`0xFaE610A10e51A09fBa8621935632b9B6F6f0DC18`](https://scrollscan.com/address/0xfae610a10e51a09fba8621935632b9b6f6f0dc18)          |
| Arbitrium | [`0xFaE610A10e51A09fBa8621935632b9B6F6f0DC18`](https://arbiscan.io/address/0xfae610a10e51a09fba8621935632b9b6f6f0dc18)             |
| Linea     | [`0xFaE610A10e51A09fBa8621935632b9B6F6f0DC18`](https://lineascan.build/address/0xfae610a10e51a09fba8621935632b9b6f6f0dc18)         |

## Contracts

This repo includes the L2 contracts required to enable subname issuance.

- [L2RegistryFactory](./src/L2RegistryFactory.sol): L2 contract for creating new registries.
- [L2Registry](./src/L2Registry.sol): L2 contract that stores subnames as ERC721 NFTs.
  It's responsible for storing subname data like address and text records.
- [L2Registrar](./src/L2Registrar.sol): An example registrar contract that can mint subnames. This is meant to be customized.

# Instructions To Deploy L2 ENS Subnames

## 1. Deploy Instance of Registry Factory

[Durin.dev](https://durin.dev/) (coming soon) provides an a GUI to do this for you.

## 2. Deploy Registrar (This is meant to be customized)

1. **Clone the repository**

   ```shell
   git clone git@github.com:resolverworks/durin.git
   cd durin
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

4. **Configure L2Registry**

   ```shell
   bash deploy/configureRegistry.sh
   ```

   The [configureRegistry.sh](https://github.com/resolverworks/durin/blob/main/deploy/configureRegistry.sh) script adds the Registrar to the Registry by calling the `addRegistrar()` method and sets pricing to 0. This grants the Registrar the ability to mint names on the Registry.

## Architecture

![diagram](https://github.com/user-attachments/assets/0ce15738-8689-4177-9efb-8bbc05d7404a)
