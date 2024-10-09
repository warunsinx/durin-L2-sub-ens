## Durin NFT Contracts

**These contracts (produced with the help of unruggable) allow you to issue NFT subnames on an L2. Follow the instructions below.**

Make sure you have foundary installed:

https://book.getfoundry.sh/

## Instructions

### Step 1: Clone this repo

```shell
$ git clone (this repo)
```

### Step 2: Rename example.env to .env and change the variables under Deploy NFTRegistry contract

```txt
# Deploy NFTRegistry contract

RPC_URL=https://your-rpc-url-here
ETHERSCAN_API_KEY= your-etherscan-api-key
PRIVATE_KEY=your-private-key-here
BASE_URI=https://your-base-uri.com/nft/
```

- RPC_URL is the RPC endpoint for your L2. You can get one from alchemy or infura.
- ETHERSCAN_API_KEY is required to verify contracts. you can get one from your L2's block explorer
- BASE_URI is where you surface your nft metadata (like images and descriptions). It can be changed later by calling setBaseURI in a block explorer

### Step 3: Deploy the NFTRegistry by running the following shell command

```shell
$ ./deploy/deployNFTRegistry.sh
```

Take a note of the Address of the deployed contract

### Step 4: In your .env change the variables under Deploy NFTRegistrar contract

```txt
# Deploy NFTRegistrar contract

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

- USD_ORACLE_ADDRESS is the oracle on your L2 that provides a conversion from USD to the L2's native currency. You can find one here https://data.chain.link/feeds
- MAX_FREE_REGISTRATIONS is maximum free names that 1 wallet can register
- MIN_COMMITMENT_AGE and MAX_COMMITMENT_AGE is used for lockups to prevent 2 wallets from claiming the same name. 0 and 120 are fine to use.
- MIN_REGISTRATION_DURATION and MAX_REGISTRATION_DURATION determine how long and short a wallet can own a name. it is in seconds
- CHAR_AMOUNTS array represents the pricing for different character lengths in the NFTRegistrar contract. The values are given in USD per second, with 18 decimal places of precision. Here is an examplation of the example values

```0: This is for 0-character names, which are free.
2029426686960: This equates to $1 per year for 1-character names.
507356671740: This equates to $4 per year for 2-character names.
126839167935: This equates to $16 per year for 3-character names.
31709791983: This equates to $64 per year for 4-character names.
```

You can change all of these except MIN_COMMITMENT_AGE and MAX_COMMITMENT_AGE in the contract by calling the appropriate function on a block explorer

### Step 5: Deploy the NFTRegistrar by running the following shell command

```shell
$ ./deploy/deployNFTRegistrar.sh
```

Take a note of the Address of the deployed contract

### Step 6: Add your registrar address to the .env

```
# Grant NFTRegistrar contract permissions

REGISTRAR_ADDRESS=0x1234567890123456789012345678901234567890
```

### Step 7: Grant the NFTRegistrar contract permissions on the NFTRegistry by running the following shell command

```shell
$ ./deploy/grantPermission.sh
```

This allows the Registrar to mint names on the Registry

### Step 8: Connect your base name to the resolver and registry

Instructions coming soon.

### You can now mint names by calling the Registrar

Check out our example frontend or build your own
