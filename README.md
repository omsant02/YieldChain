# YieldChain

> Multi-asset Aave vault with double-impact public goods funding

**Octant DeFi Hackathon 2025**

---

## The Innovation

Traditional DeFi strategies donate **one** revenue stream. YieldChain donates **two**:

1. **Aave lending yield** → Public goods (automated)
2. **Rebalancing swap fees** → Public goods (via custom Uniswap V4 hook)

Every optimization = more funding.

---

## Architecture
```
┌─────────────────┐
│  Users deposit  │
│  USDC/DAI/USDT  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ MultiAssetAaveStrategy  │
│  • ERC-4626 compliant   │
│  • Yield → Dragon Router│
└───────┬─────────────────┘
        │
        ├──────────────┬──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │ aUSDC   │   │  aDAI   │   │ aUSDT   │
   │ Vault   │   │ Vault   │   │ Vault   │
   └────┬────┘   └────┬────┘   └────┬────┘
        │             │             │
        └─────────────┴─────────────┘
                  │
        ┌─────────▼─────────┐
        │   Aave V3 Pool    │
        │   (yield source)  │
        └───────────────────┘

When rebalancing:
   USDC → [Uniswap V4 Pool + Hook] → DAI
                    │
                    └─→ 0.01% fee → Dragon Router
```

---

## Complete Flow

### 1. User Deposits (Automated)
```
User → deposit(USDC) → Strategy mints shares 1:1
                     → ATokenVault.deposit()
                     → Aave V3 Pool receives USDC
                     → aUSDC accrues interest
```

**Result:** User has shares, funds earning yield in Aave.

---

### 2. Yield Donation (Automated)
```
Keeper → strategy.report()
      → Calculate total assets (deployed + idle)
      → Profit = current - previous
      → YieldDonatingTokenizedStrategy mints shares to Dragon Router
```

**Result:** All Aave interest converted to donation shares automatically.

---

### 3. Rebalancing (Governance-Triggered)

When USDC APY drops but DAI APY rises, governance rebalances:

**Step 1: Initiate**
```
Management → initiateRebalance(5000e6)
          → Strategy withdraws 5000 USDC from Aave
          → USDC sits idle in strategy
```

**Step 2: Swap (External)**
```
Management → Swaps via Uniswap V4 interface
          → USDC → DAI swap executes
          → PublicGoodsSwapHook triggers on afterSwap
          → Hook takes 0.01% (5 DAI)
          → Hook sends fee to Dragon Router
          → Strategy receives 4995 DAI
```

**Step 3: Complete**
```
Management → completeRebalance(DAI)
          → Strategy deposits 4995 DAI to Aave
          → Now earning DAI yield instead
```

**Result:** 
- Strategy optimized for better APY
- Swap fee donated to public goods
- Future yields now in DAI

---

### 4. User Withdrawal (Anytime)
```
User → withdraw(shares)
    → Strategy burns shares
    → Withdraws from current Aave vault
    → Returns underlying asset
```

**Result:** User gets principal back (yield was donated).

---

## Key Features

### ✅ Multi-Asset ERC-4626 Vaults
- Custom `ATokenVault` wrapper for Aave V3
- Supports USDC, DAI, USDT in one strategy
- Standard ERC-4626 interface for composability

### ✅ Automated Yield Donation
- Inherits Octant's `BaseStrategy`
- All Aave interest → minted as shares to Dragon Router
- Keeper calls `report()` periodically
- User principal stays 1:1

### ✅ Fee-Capturing Hook
- `PublicGoodsSwapHook` on Uniswap V4
- Takes 0.01% of every swap output
- Sends directly to Dragon Router
- **Proven: 598B wei donated per test swap**

### ✅ Governance Rebalancing
- Management decides when to rebalance
- Two-step process for safety and flexibility
- Can use any swap route (Uniswap V4, Cowswap, etc.)
- Hook captures fee regardless of route choice

---

## Smart Contracts

| Contract | Purpose | LOC |
|----------|---------|-----|
| `MultiAssetAaveStrategy.sol` | Main vault, handles deposits/yields/rebalancing | 150 |
| `ATokenVault.sol` | ERC-4626 wrapper for Aave aTokens | 60 |
| `PublicGoodsSwapHook.sol` | Uniswap V4 fee capture | 80 |

---

## Test Results
```bash
forge test

Ran 4 test suites: 12 tests passed, 0 failed

✓ Vault deployment & configuration
✓ Strategy ERC-4626 compliance  
✓ Hook captures swap fees (598B wei donated)
✓ Full rebalancing flow (initiate → swap → complete)
```

---

## Quick Start
```bash
# Clone
git clone https://github.com/YOUR_USERNAME/yieldchain-double-impact
cd yieldchain-double-impact

# Setup
cp .env.example .env
# Add ETH_RPC_URL to .env

# Install & build
forge install
forge build

# Test
forge test -vv
```

---

## Roles & Permissions

| Role | Can Do | Purpose |
|------|--------|---------|
| **User** | Deposit, withdraw | Provide capital |
| **Keeper** | Call `report()` | Trigger yield donation |
| **Management** | Initiate/complete rebalance | Optimize APY |
| **Emergency Admin** | Emergency withdrawal | Safety valve |

---

## Why Manual Rebalancing?

**Design Choice:** We use governance-triggered rebalancing instead of automated for:

1. **Safety** - No automated swap risks or MEV attacks
2. **Flexibility** - Can use best route at execution time
3. **Gas Efficiency** - Rebalance only when needed
4. **Production Reality** - Most protocols (Yearn, Enzyme) use manual

The hook still captures fees regardless of swap route.

---

## Tech Stack

- **Solidity 0.8.26**
- **Foundry** (testing framework)
- **OpenZeppelin** (ERC-4626, SafeERC20)
- **Octant V2** (BaseStrategy, YieldDonatingTokenizedStrategy)
- **Uniswap V4** (Hooks, PoolManager)
- **Aave V3** (Lending pools, aTokens)

---

## Security

- Inherits audited Octant BaseStrategy
- Uses battle-tested Aave V3 pools
- Follows Uniswap V4 hook patterns
- Manual rebalancing = no automated swap risks
- Emergency withdrawal functions
- All roles use standard Octant access control

---

## License

MIT

---

**Built for Octant DeFi Hackathon 2025**

*Double the donation, double the impact* 💚
