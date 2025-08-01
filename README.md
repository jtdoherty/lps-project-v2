# Liquid LP Yield Protocol

[![Discord](https://img.shields.io/discord/YOUR_DISCORD_ID?label=Discord&logo=discord)](https://discord.gg/YOUR_INVITE_LINK)
[![Twitter](https://img.shields.io/twitter/follow/YOUR_TWITTER_HANDLE?style=social)](https://twitter.com/YOUR_TWITTER_HANDLE)

The Liquid LP Yield Protocol introduces `lpUSD`, a decentralized stablecoin, and `wlpUSD` (wrapped lpUSD), its yield-bearing counterpart. The protocol is built on top of battle-tested DeFi primitives like Yearn Finance to provide a simple and secure way to earn yield on stablecoins.

## Vision & Core Principles

-   **Separation of Concerns:** Provides two distinct tokens: `lpUSD` for stable, predictable composability and `wlpUSD` for passive, value-accruing yield.
-   **Simplicity through Abstraction:** By building on top of Yearn, the protocol's sole focus is on a streamlined user experience for minting, staking, and redeeming assets.
-   **Security through Dependency:** The security model inherits the robustness of Yearn Finance. The primary risk is the security of the underlying Yearn vault, a well-audited and trusted primitive.

---

## How It Works

The protocol allows users to deposit stablecoins, receive a 1:1 pegged stablecoin (`lpUSD`), and then stake `lpUSD` to earn yield through a wrapped, interest-bearing token (`wlpUSD`).

### Core Components

1.  **`lpUSD` Token:** A non-yield-bearing ERC20 stablecoin, fully backed by yield-bearing tokens from Yearn Finance vaults.
2.  **`wlpUSD` Token:** A yield-bearing ERC20 token that represents a user's share of the staked `lpUSD` pool. Its value appreciates as the underlying Yearn Vault generates yield.
3.  **`DepositController.sol`:** The main user-facing contract for minting `lpUSD` by depositing stablecoins, and redeeming `lpUSD` back to the underlying stablecoins.
4.  **`StakingPool.sol`:** The contract where users stake their `lpUSD` to receive `wlpUSD`, and unstake to claim their principal plus accrued yield.

### User Journey

1.  **Mint:** User deposits a stablecoin (like `USDC`) into the `DepositController` and mints an equivalent amount of `lpUSD`.
2.  **Stake:** User stakes their `lpUSD` in the `StakingPool` to receive `wlpUSD`.
3.  **Accrue Yield:** The protocol's treasury (held in the `DepositController`) earns yield from the underlying Yearn Vault. This yield is periodically harvested, increasing the value of the `wlpUSD` token.
4.  **Unstake:** The user unstakes their `wlpUSD` to receive their original `lpUSD` plus any yield earned.
5.  **Redeem:** The user redeems their `lpUSD` through the `DepositController` to get back the underlying stablecoin.

---

## Getting Started

### Prerequisites

-   [**Foundry**](https://book.getfoundry.sh/getting-started/installation): A blazing fast, portable and modular toolkit for Ethereum application development.

### Installation

1.  **Clone the repository:**
    ```shell
    git clone https://github.com/YOUR_USERNAME/lps-project-v2.git
    cd lps-project-v2
    ```

2.  **Install dependencies:**
    ```shell
    forge install
    ```

---

## Usage

### Testing

Run the full test suite with:
    ```shell
    forge test
    ```
To see a test coverage report, run:
    ```shell
    forge coverage
    ```

## Deployment

To deploy the contracts, first create a .env file by copying the example:
    ```shell
    cp .env.example .env
    ```
Then, populate your .env file with your SEPOLIA_RPC_URL and PRIVATE_KEY.
    ```shell
    SEPOLIA_RPC_URL=YOUR_RPC_URL
    PRIVATE_KEY=YOUR_WALLET_PRIVATE_KEY
    ```
Finally, run the deployment script:
    ```shell
    forge script script/DeployAll.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
    ```

---

### Deployed Contract (Sepolia)

- USDC (Mock): 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
- LpUSD Token: 0xaFbc931df4D043F5DcB53D45336b1614fc5e327C
- SlpUSD Token: 0x9a3CFdcDD901f551fC680591BaC3933764dd8104
- DepositController: 0xB2E010Da8489ead62434b3705d5DD06d36D9EfAb
- StakingPool: 0x7a509C9bD6F76c8BB5Bd9Bfa10FE6922E70d1d22

## Contributing & Security Review

This project is currently in an experimental phase and is undergoing review before any potential mainnet launch. I am actively seeking feedback from the community, especially from developers with experience in DeFi and smart contract security.

### Areas for Review

- Logic & Design: Are there any flaws in the core tokenomic or architectural design?
- Security Vulnerabilities: Are there any potential attack vectors (e.g., reentrancy, price manipulation, economic exploits)?
- Gas Optimization: Are there opportunities to make the contracts more gas-efficient?
- Best Practices: Does the code adhere to modern Solidity standards and best practices?

This codebase has not yet been audited by a professional security firm. Please review the code carefully before use and do not risk any funds you are not prepared to lose.