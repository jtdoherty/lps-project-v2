## Liquid LP Yield Protocol: Formal Architecture (v1)

### 1. Vision & Core Principles

The protocol introduces `lpUSD`, a highly composable, decentralized stablecoin, and `wlpUSD`, its yield-bearing counterpart. The system leverages Yearn Finance's yield-optimizing vaults to generate returns, offering users a simple, secure, and powerful way to earn on their stablecoins.

*   **Principle 1: Separation of Concerns.** The protocol provides two distinct tokens: `lpUSD` for stable, predictable composability and `wlpUSD` for passive, value-accruing yield.
*   **Principle 2: Simplicity through Abstraction.** By building on top of Yearn, our protocol does not need to manage complex yield strategies. Its sole focus is minting, redeeming, and staking.
*   **Principle 3: Security through Dependency.** Our security model inherits the robustness of Yearn Finance. The primary risk is the security of the underlying Yearn vault, a well-audited and trusted primitive.

### 2. Core Components

The system consists of user-facing assets, a backend yield component (Yearn), and our core smart contracts.

1.  **User Assets:**
    *   **Input Stablecoins:** `USDC`, `USDT` (or others supported by the chosen Yearn Vault).
    *   **`lpUSD` Token:** A non-yield-bearing ERC20 stablecoin, pegged 1:1 to the US dollar upon minting. Its supply is fully backed by the value of Yearn Vault tokens (`yvTokens`) held by the protocol.
    *   **`wlpUSD` Token:** A yield-bearing ERC20 token. It represents a user's share of the staked `lpUSD` pool. Its value (in terms of `lpUSD`) increases over time as the underlying Yearn Vault generates yield.

2.  **Backend Yield Engine (Dependency):**
    *   **Yearn Finance Vault:** A specific vault that accepts stablecoins and optimizes yield via Curve/Convex strategies.
    *   **Example Vault:** [crvUSDTWBTCWETH](https://yearn.fi/v2/0x2E224865f3aA4269175a250326442AbBdc596b79) (This is an example, we'd select the most appropriate one, likely a pure stablecoin vault like `yvCurve-USDC-USDT` if available and suitable).
    *   **`yvToken`:** The receipt token from the Yearn Vault (e.g., `yvcrvUSDCUSDT`). This is the actual asset our protocol holds in its treasury. The value of this token appreciates over time.

3.  **Protocol Smart Contracts:**
    *   **`DepositController.sol` (The Vault):** The primary user-facing contract. It holds all `yvTokens`. It is responsible for minting and burning `lpUSD`.
    *   **`StakingPool.sol` (The Yield Director):** The contract that manages the `lpUSD` <-> `wlpUSD` relationship. Users stake their `lpUSD` here to receive `wlpUSD`.
    *   **`PriceOracle.sol`:** A simple contract that reads the price of the `yvToken` directly from the Yearn Vault contract (`pricePerShare` function). This is crucial for calculating the total value locked (TVL) and the `wlpUSD` exchange rate.

### 3. System Workflows (User Journeys)

#### A. The Primary Path: User Deposits Stablecoins to Mint `lpUSD`

1.  **User Action:** A user deposits 1,000 `USDC` into the `DepositController`.
2.  **Protocol Action:**
    a. The `DepositController` receives the 1,000 `USDC`.
    b. It calls the `deposit()` function on the target Yearn Vault contract, depositing the 1,000 `USDC`.
    c. The Yearn Vault mints and transfers a corresponding amount of `yvTokens` back to our `DepositController`.
    d. The `DepositController` mints exactly 1,000 `lpUSD` and sends them to the user.

*Result: The user holds 1,000 `lpUSD`, a stable and composable token. The protocol's treasury now holds `yvTokens` worth $1,000.*

#### B. The Yield Path: User Stakes `lpUSD` to Receive `wlpUSD`

1.  **User Action:** The user approves the `StakingPool` contract to spend their `lpUSD`, then calls `stake(500 lpUSD)`.
2.  **Protocol Action:**
    a. The `StakingPool` contract pulls 500 `lpUSD` from the user.
    b. It calculates the number of `wlpUSD` to mint based on the current exchange rate.
    c. It mints and transfers the calculated `wlpUSD` to the user.

*Result: The user holds `wlpUSD`, which will grow in value. The staked `lpUSD` are held by the `StakingPool` contract.*

#### C. The Unstaking Path: User Swaps `wlpUSD` back to `lpUSD`

1.  **User Action:** User calls `unstake(wlpUSD_amount)` on the `StakingPool`.
2.  **Protocol Action:**
    a. The contract burns the user's `wlpUSD`.
    b. It calculates the corresponding amount of `lpUSD` to return based on the *current, appreciated* exchange rate.
    c. It transfers the `lpUSD` from its own balance back to the user.

*Result: The user receives more `lpUSD` than they originally staked (assuming positive yield).*

#### D. The Exit Path: User Redeems `lpUSD` for Underlying Stablecoins

1.  **User Action:** User calls `redeem(1,000 lpUSD)` on the `DepositController`.
2.  **Protocol Action:**
    a. The `DepositController` burns the user's 1,000 `lpUSD`.
    b. It calculates the amount of `yvTokens` it needs to redeem to get $1,000 worth of underlying stablecoins. It does this using the `PriceOracle` (`pricePerShare`).
    c. It calls the `withdraw(1000)` function on the Yearn Vault contract.
    d. The Yearn Vault burns the `yvTokens` from our protocol and sends back ~1,000 of the underlying stablecoins (e.g., `USDC` or `USDT`, minus any small fees).
    e. The `DepositController` transfers the stablecoins to the user.

*Result: The user has successfully exited their position back to a primary stablecoin.*

### 4. Token & Value Accrual Mechanics

This is the core of the `wlpUSD` design.

*   **`lpUSD`:** Remains pegged to $1. Its value does not change.
*   **Yield Source:** The `yvTokens` held by the `DepositController` constantly increase in value due to Yearn's auto-compounding strategies. Yearn's `pricePerShare` function reflects this growth.
*   **`wlpUSD` Exchange Rate:** The value of `wlpUSD` is determined by the total yield generated by the system, distributed proportionally among stakers.

The exchange rate is calculated as follows:

**`Rate = totalValueStakedInUSD / wlpUSD.totalSupply()`**

Where `totalValueStakedInUSD` is:
`StakingPool.totalLpUSDStaked() * (PriceOracle.getYVTokenPrice() / lpUSD.initialPegValue)`

This effectively means that as the value of the `yvTokens` in the main vault grows, each `lpUSD` held within the `StakingPool` represents a claim on a slightly larger portion of that value. This appreciation is passed directly to `wlpUSD` holders via the exchange rate.

### 5. Smart Contract Skeletons


// --- Token Contracts ---
interface IERC20 { /* ... standard functions ... */ }
interface IYearnVault {
    function deposit(uint256 amount) external returns (uint256);
    function withdraw(uint256 maxShares) external returns (uint256);
    function pricePerShare() external view returns (uint256);
}

// lpUSD: Standard OpenZeppelin ERC20 with Ownable/AccessControl for minting
contract LpUSDToken is ERC20, AccessControl { /* ... */ }

// WlpUSD: Standard OpenZeppelin ERC20 with Ownable/AccessControl for minting
contract WlpUSDToken is ERC20, AccessControl { /* ... */ }


// --- Core Protocol Contracts ---

contract PriceOracle {
    IYearnVault public immutable yvTokenVault;

    constructor(address _yvTokenAddress) {
        yvTokenVault = IYearnVault(_yvTokenAddress);
    }

    function getPricePerShare() public view returns (uint256) {
        // Returns the value of one share (yvToken) in terms of the underlying asset
        return yvTokenVault.pricePerShare();
    }
}

contract DepositController {
    IERC20 public immutable underlyingStable;
    IYearnVault public immutable yvTokenVault;
    LpUSDToken public immutable lpUSD;

    // --- Functions ---
    function deposit(uint256 amount) external; // Mints lpUSD
    function redeem(uint256 lpUSDAmount) external; // Burns lpUSD
}

contract StakingPool {
    LpUSDToken public immutable lpUSD;
    WlpUSDToken public immutable wlpUSD;
    PriceOracle public immutable oracle;

    // --- Functions ---
    function stake(uint256 lpUSDAmount) external; // Deposits lpUSD, mints wlpUSD
    function unstake(uint256 wlpUSDAmount) external; // Burns wlpUSD, returns lpUSD
    function exchangeRate() public view returns (uint256); // The core value accrual function
}"
