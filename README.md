# Kalijo kUSD/USDC Swap Contract

This repository contains a contract to swap kUSD and USDC at configurable exchange rates with fee management.

## Overview

The KUSDUSDCSwap contract provides a simple and secure way to swap between KUSD and USDC tokens. It includes features such as:

- Configurable exchange rate
- Adjustable fee percentage
- Fee accumulation and withdrawal
- Token balance monitoring
- Reentrancy protection
- SafeERC20 implementation for security

## Contract Details

### Key Features

- **Token Swapping**: Bidirectional swaps between KUSD and USDC
- **Exchange Rate Management**: Configurable exchange rate that can be updated by the owner
- **Fee Collection**: Fees are collected on each swap and can be withdrawn by the owner
- **Security Measures**: Uses OpenZeppelin's ReentrancyGuard and SafeERC20
- **Owner Withdrawal**: Owner can withdraw tokens in case of emergencies or to rebalance token amounts.
- **Emergency Pause**: Owner can pause all swap operations in case of emergencies

### Functions

| Function | Description | Access |
|----------|-------------|--------|
| `swapKUSDforUSDC(uint256 amount)` | Swap KUSD for USDC | Public |
| `swapUSDCforKUSD(uint256 amount)` | Swap USDC for KUSD | Public |
| `setExchangeRate(uint256 newRate)` | Update the exchange rate | Owner Only |
| `setFeeRate(uint256 newFeeRate)` | Update the fee rate | Owner Only |
| `withdrawFees(address token)` | Withdraw collected fees | Owner Only |
| `withdrawTokens(address token, uint256 amount)` | Emergency token withdrawal | Owner Only |
| `pause()` | Pause all swap operations | Owner Only |
| `unpause()` | Resume swap operations | Owner Only |

### Events

| Event | Description |
|-------|-------------|
| `Swapped(address indexed user, bool kusdToUsdc, uint256 amountIn, uint256 amountOut, uint256 feeAmount)` | Emitted when a swap occurs |
| `ExchangeRateUpdated(uint256 newRate)` | Emitted when the exchange rate is updated |
| `FeeRateUpdated(uint256 newFeeRate)` | Emitted when the fee rate is updated |
| `FeesWithdrawn(address indexed token, uint256 amount)` | Emitted when fees are withdrawn |
| `Paused(address account)` | Emitted when the contract is paused |
| `Unpaused(address account)` | Emitted when the contract is unpaused |

### State Variables

| Variable | Type | Description | Default Value |
|----------|------|-------------|---------------|
| `kusd` | IERC20 | KUSD token contract | Set in constructor |
| `usdc` | IERC20 | USDC token contract | Set in constructor |
| `exchangeRate` | uint256 | Exchange rate (1 KUSD = x USDC * 10^-6) | 1,000,000 (1:1) |
| `feeRate` | uint256 | Fee percentage in basis points (1 bp = 0.01%) | 30 (0.3%) |
| `collectedKUSDFees` | uint256 | Accumulated KUSD fees | 0 |
| `collectedUSDCFees` | uint256 | Accumulated USDC fees | 0 |

### Access Control

The contract uses OpenZeppelin's Ownable contract for access control:

- **Owner**: Can update exchange rates, fee rates, and withdraw tokens/fees
- **Users**: Can perform token swaps if they have the required tokens

## Technical Notes

- **Exchange Rate Mechanism**: The exchange rate is stored with 6 decimals of precision. For example, a value of 1,000,000 represents a 1:1 exchange rate between KUSD and USDC.

- **Fee Calculation**: Fees are calculated in basis points (1 basis point = 0.01%). The default fee is 0.3% (30 basis points).

- **SafeERC20**: The contract uses OpenZeppelin's SafeERC20 to ensure compatibility with tokens that don't strictly follow the ERC20 standard.

- **Reentrancy Protection**: All swap functions are protected against reentrancy attacks using OpenZeppelin's ReentrancyGuard.

- **Pause Mechanism**: The contract can be paused by the owner in case of emergencies, which halts all swap operations until the contract is unpaused.

- **Token Flow**:
  - When swapping KUSD for USDC, the contract takes KUSD from the user and sends USDC to the user
  - When swapping USDC for KUSD, the contract takes USDC from the user and sends KUSD to the user
  - Fees are accumulated in the output token (USDC for KUSD→USDC swaps, KUSD for USDC→KUSD swaps)

- **Failure Handling**: The contract safely reverts if there are insufficient tokens, insufficient approvals, or other conditions that would prevent a successful swap.

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
KUSD_ADDRESS=0x0000000000000000000000000000000000000000
USDC_ADDRESS=0x0000000000000000000000000000000000000000
```

## Testing

To run the tests, run the following command:

``` bash
forge test
```

The test suite includes tests for:

- Basic swap functionality in both directions
- Exchange rate updates
- Fee collection and withdrawal
- Error handling for insufficient tokens, approvals, and balances
- Pause and unpause functionality

## Deployment

To deploy the contract, run the following command:

``` bash
export RPC_URL=your_rpc_url
forge script script/DeployKUSDUSDCSwap.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --legacy --ffi
```

This will output the deployed addresses to the console and save them to the `script/config/Deploy.json` file.