# CrowdFund

A small Ethereum crowdfunding project. The `Campaign` contract holds backers' ETH until its deadline: the creator can withdraw if the goal was met, and backers can reclaim their contributions if it was not. A static browser interface reads campaign state and lets users interact through a browser wallet.

## Features

- Campaign creator, fundraising goal, and deadline are fixed at deployment.
- Contributions are tracked per backer and added to the total raised.
- After the deadline, the creator can withdraw the full balance once if the goal was reached.
- If the goal was missed, each backer can refund their own contribution.
- The web interface displays campaign and wallet state, supports contributions/withdrawals/refunds, and shows contract events.

The goal is specified in wei at deployment. The web interface displays ETH.

## Requirements

- [Foundry](https://book.getfoundry.sh/) (`forge` and `anvil`)
- A browser with an EIP-1193-compatible wallet for sending transactions
- Python 3 or another local static-file server for serving the web page

## Run locally

1. Start a local Ethereum node in a terminal:

   ```sh
   anvil
   ```

   The frontend's sample configuration uses the Anvil RPC endpoint `http://127.0.0.1:8545` and chain ID `31337`.

2. Deploy `contracts/Campaign.sol` to that node. For example, with Foundry, set the constructor arguments to a goal in wei and a duration in minutes:

   ```sh
   forge create contracts/Campaign.sol:Campaign \
     --rpc-url http://127.0.0.1:8545 \
     --private-key <ANVIL_TEST_ACCOUNT_PRIVATE_KEY> \
     --constructor-args <GOAL_IN_WEI> <DURATION_IN_MINUTES>
   ```

   Use only a local Anvil test account; never use a real wallet key for local development. Record the deployed contract address and deployment block.

3. Update [`deployment.json`](./deployment.json) with the deployment's address, block, and ABI, and ensure its `chainId` and `rpcUrl` match the node. The checked-in values describe a local Anvil deployment and may not match a fresh node's state.

4. Serve the repository root over HTTP (the page loads `deployment.json` from its parent directory):

   ```sh
   py -m http.server 8000
   ```

   Open [http://localhost:8000/web/](http://localhost:8000/web/) in the browser. Add or select the local Anvil network in the wallet, then connect a wallet account to contribute or perform the eligible post-deadline action.

The frontend reads the contract using the RPC URL in `deployment.json`; a wallet is only needed to submit transactions. Wallet transactions must use the same chain as the deployed campaign.

## Contract behavior

| Action | Conditions |
| --- | --- |
| `contribute()` | Before the deadline; contribution must be greater than zero. |
| `withdraw()` | Only the creator, after the deadline, if the goal was reached, and only once. |
| `refund()` | After the deadline, if the goal was missed, and only for an account with a recorded contribution. |

The contract is an escrow for a single campaign. It has no campaign factory, fees, or early withdrawal/refund path.

## Tests

[`tests/Campaign_test.sol`](./tests/Campaign_test.sol) is written for Remix's Solidity Unit Testing plugin and imports Remix's `remix_tests.sol`; open it in Remix and run it with that plugin. [`tests/Backer.sol`](./tests/Backer.sol) is a helper contract used by those tests.

The repository's `foundry.toml` points Foundry at `instructor-check/test`, which is not the location of these Remix tests. The checked-in test files are therefore not a standalone Foundry test suite.

## Project layout

```text
contracts/Campaign.sol   Crowdfunding escrow contract
tests/                   Remix Solidity unit tests and helper
web/                     Browser interface, styles, and bundled viem client
deployment.json          Network, contract address, and ABI used by the interface
foundry.toml             Foundry compiler and path configuration
```

## Development note

This project is intended for local development and learning. Review the contract and deployment configuration before using it with real funds.
