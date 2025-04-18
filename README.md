# Kalijo kUSD/USDC Swap Contract

This repository contains a contract to swap kUSD and USDC at 1:1 trade levels.

## Prerequisites

If you are using Windows, you can use WSL to deploy and interact with the contracts through the CLI.

To deploy and interact with the contracts through the CLI, use the Forge scripts provided in this repository and described further below. First, install Foundry (<https://book.getfoundry.sh/getting-started/installation>) and the OpenZeppelin contracts before proceeding with the deployment (this is the 0.8.10 version):

``` bash
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

Make sure to setup the environment variables in your `.env` file:

``` bash
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url
FEE_ADDRESS=0x...
```
