# Durin NFT Contracts

These contracts, produced with the help of Unruggable, allow you to issue NFT subnames on an L2 network. Follow the instructions below to set up and deploy the contracts.

## Prerequisites

Ensure you have [Foundry](https://book.getfoundry.sh/) installed.

## Setup and Deployment

1. **Clone the repository**

   ```shell
   git clone git@github.com:resolverworks/durin-nft-contracts.git
   cd durin-nft-contracts
   ```

2. **Set up environment variables**

   Copy `example.env` to `.env` and update the following variables:

   ```env
   # NFTRegistry contract deployment
   RPC_URL=https://your-rpc-url-here
   ETHERSCAN_API_KEY=your-etherscan-api-key
   PRIVATE_KEY=your-private-key-here
   BASE_URI=https://your-base-uri.com/nft/
   ```

   - `RPC_URL`: RPC endpoint for your L2 (available from Alchemy or Infura)
   - `ETHERSCAN_API_KEY`: Required for contract verification (obtain from your L2's block explorer)
   - `BASE_URI`: URL for your NFT metadata (can be updated later via `setBaseURI`)

3. **Deploy NFTRegistry contract**

   ```shell
   bash deploy/deployNFTRegistry.sh
   ```

   Note the deployed contract address.

4. **Update .env for NFTRegistrar deployment**

   Add the following variables to your `.env` file:

   ```env
   # NFTRegistrar contract deployment
   REGISTRY_ADDRESS=0x1234567890123456789012345678901234567890
   USD_ORACLE_ADDRESS=0x9876543210987654321098765432109876543210
   MIN_CHARS=1
   MAX_CHARS=42
   MAX_FREE_REGISTRATIONS=7
   MIN_COMMITMENT_AGE=0
   MAX_COMMITMENT_AGE=120
   MIN_REGISTRATION_DURATION=2592000
   MAX_REGISTRATION_DURATION=15552000
   CHAR_AMOUNTS="0 2029426686960 507356671740 126839167935 31709791983"
   ```

   Explanations:

   - `REGISTRY_ADDRESS`: Address of the deployed NFTRegistry contract
   - `USD_ORACLE_ADDRESS`: Oracle for USD to L2 native currency conversion (find at [Chainlink Data Feeds](https://data.chain.link/feeds))
   - `MIN_CHARS` and `MAX_CHARS`: Minimum and maximum allowed characters for names
   - `MAX_FREE_REGISTRATIONS`: Maximum number of free names one wallet can register
   - `MIN_COMMITMENT_AGE` and `MAX_COMMITMENT_AGE`: Used for lockups to prevent two wallets from claiming the same name (in seconds). It is fine to use the defaults if you are unsure.
   - `MIN_REGISTRATION_DURATION` and `MAX_REGISTRATION_DURATION`: Minimum and maximum duration a wallet can own a name (in seconds)
   - `CHAR_AMOUNTS`: Pricing for different name lengths (in USD per second, 18 decimal places). See the Notes at the bottom of the page for a complete explanation.

   Note: All parameters except `MIN_COMMITMENT_AGE` and `MAX_COMMITMENT_AGE` can be changed later by calling the appropriate function on a block explorer.

5. **Deploy NFTRegistrar contract**

   ```shell
   bash deploy/deployNFTRegistrar.sh
   ```

   Note the deployed contract address.

6. **Grant permissions to NFTRegistrar**

   Add the Registrar address to your `.env`:

   ```env
   REGISTRAR_ADDRESS=0x1234567890123456789012345678901234567890
   ```

   Then run:

   ```shell
   bash deploy/grantPermission.sh
   ```

   This allows the Registrar to mint names on the Registry.

7. **Connect base name to resolver and registry**

   (Instructions to be added)

## Usage

You can now mint names by calling the Registrar. Check out our example frontend or build your own.

## Notes

### CHAR_AMOUNTS Calculation

The `CHAR_AMOUNTS` array represents pricing for different name lengths in USD per second, with 18 decimal places of precision. Here's how the example values are calculated:

1. Start with the desired yearly price in USD for each name length.
2. Convert the yearly price to a per-second price.
3. Multiply by 10^18 to add 18 decimal places of precision.

Example calculation for 1-character names:

- Desired price: $1 per year
- Per second: $1 / (365 _ 24 _ 60 \* 60) ≈ $0.0000000317098
- With 18 decimal places: 0.0000000317098 \* 10^18 = 31709791983

The `CHAR_AMOUNTS` array in the example represent:

- Index 0: 0-character names (free)
- Index 1: 1-character names ($1/year) = 2029426686960
- Index 2: 2-character names ($4/year) = 507356671740
- Index 3: 3-character names ($16/year) = 126839167935
- Index 4: 4-character names ($64/year) = 31709791983

You can adjust these values to set your desired pricing structure for different name lengths.
