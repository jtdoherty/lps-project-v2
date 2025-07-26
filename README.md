## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```




















current user journey: 

This is the permanent set of addresses. Please delete all old ones. This is your live, working system.

Sepolia USDC Faucet: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
Your LpUSD Token: 0xaFbc931df4D043F5DcB53D45336b1614fc5e327C
Your SlpUSD Token: 0x9a3CFdcDD901f551fC680591BaC3933764dd8104
Your DepositController: 0xB2E010Da8489ead62434b3705d5DD06d36D9EfAb
Your StakingPool: 0x7a509C9bD6F76c8BB5Bd9Bfa10FE6922E70d1d22
Your MockYVault: 0x1b86A7a94412BFF1a898463272473b3986222840
The Full User Journey: A Step-by-Step Guide to Victory
We will now perform the full user journey with 10 USDC. This time, it will work perfectly, and you will see your profit.

Journey A: Deposit USDC for lpUSD
Approve: Go to the USDC Contract, connect your wallet, and call approve.
spender: 0xB2E010Da8489ead62434b3705d5DD06d36D9EfAb (Your DepositController)
amount: 10000000
Deposit: Go to your DepositController and call deposit.
_amount: 10000000
SUCCESS CHECKPOINT: You will have 10 lpUSD in your wallet.
Journey B: Stake lpUSD for slpUSD
Approve: Go to your LpUSD Token and approve your StakingPool.
spender: 0x7a509C9bD6F76c8BB5Bd9Bfa10FE6922E70d1d22 (Your StakingPool)
amount: 10000000
Stake: Go to your StakingPool and call stake.
_amount: 10000000
SUCCESS CHECKPOINT: You will have 10 slpUSD.
Journey C: Simulate Yield (The Admin Part)
Add Profit to Vault: First, make the vault solvent.
Go to the USDC Contract and approve your MockYVault (0x1b86...) for 1000000 (1 USDC profit).
Go to your MockYVault and call drip with 1000000.
Update Vault's Value: Now, do the accounting.
On the same MockYVault page, call setPricePerShare with 1100000000000000000.
SUCCESS CHECKPOINT: The vault now holds 11 USDC and knows its shares are worth 10% more.
Journey D: Harvest the Profit (THE KEY TO VICTORY)
This is the step that makes the entire economic model work.

Harvest: Go to your DepositController. Connect your wallet. Call function 3. harvest. It has no parameters.
WHAT JUST HAPPENED: This transaction calculated the 1 USDC of profit and minted 1 new lpUSD, sending it directly to the StakingPool. The pool is now solvent and holds 11 lpUSD.
Journey E: Unstake and Go Home Richer
Approve Unstake: Go to your SlpUSD Token and approve your StakingPool (0x7a50...) for 10000000.
Unstake for Profit: Go to your StakingPool and unstake 10000000 shares.
THE PAYOFF: Check your wallet. You will now have 11 lpUSD. The profit is yours.
Approve Redeem: Go to your LpUSD Token and approve your DepositController (0xB2E0...) for 11000000.
Redeem: Go to your DepositController and redeem 11000000.
FINAL VICTORY: Your USDC balance will increase by 11.
