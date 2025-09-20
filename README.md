# TreeVibe

TreeVibe is a payment system with real-time earnings tracking and leaderboard functionality. The system enables efficient gas usage by updating user earnings in real-time during payment processing, eliminating the need for expensive recalculations during leaderboard queries.

## Features

- **Real-time Earnings Tracking**: Automatically updates `totalEarnings` and `weeklyEarnings` when users receive payments
- **Gas-Efficient Leaderboard**: Query user earnings without expensive on-chain calculations
- **Weekly Reset Mechanism**: Administrative functions to reset weekly earnings for fair competition
- **USDT Integration**: Uses USDT token for payments with 6-decimal precision

## Contract Architecture

### TreeVibe Contract
The main contract that handles payments and earnings tracking.

**Key Functions:**
- `payUser(address user, uint256 amount)` - Pay a user and update earnings in real-time
- `userOf(address user)` - Get user's total and weekly earnings (leaderboard compatible)
- `resetWeeklyEarnings()` - Reset weekly earnings (owner only)
- `batchResetWeeklyEarnings(address[] users)` - Batch reset for gas efficiency

### Leaderboard Contract
Provides efficient access to earnings data without recalculation.

**Key Functions:**
- `getUserEarnings(address user)` - Get detailed earnings for one user
- `getBatchUserEarnings(address[] users)` - Batch query for multiple users
- `compareTotalEarnings(address userA, address userB)` - Compare total earnings
- `compareWeeklyEarnings(address userA, address userB)` - Compare weekly earnings

### MockUSDT Contract
ERC20 token contract for testing and development.

## Development

### Setup
```bash
npm install
```

### Compile Contracts
```bash
npm run compile
```

### Run Tests
```bash
npm test
```

## Contract Addresses and Descriptions

| Contract Name | Contract Address | Description |
|----------------|------------------|-------------|
| TreeVibe | TBD | Main payment system with real-time earnings tracking |
| Leaderboard | TBD | Gas-efficient leaderboard query interface |
| MockUSDT | TBD | Test USDT token (6 decimals) for development |

*Contract addresses will be updated after deployment.*

## Usage Example

```solidity
// Deploy contracts
MockUSDT usdt = new MockUSDT();
TreeVibe treeVibe = new TreeVibe(address(usdt));
Leaderboard leaderboard = new Leaderboard(address(treeVibe));

// Pay a user (updates earnings automatically)
usdt.approve(address(treeVibe), 1000000); // 1 USDT
treeVibe.payUser(userAddress, 1000000);

// Query earnings via leaderboard
(uint256 total, uint256 weekly) = treeVibe.userOf(userAddress);
```

## Gas Optimization

The system optimizes gas usage by:
1. **Real-time Updates**: Earnings are updated during payment, not during queries
2. **Batch Operations**: Multiple users can be processed in single transactions
3. **View Functions**: Leaderboard queries use view functions with no gas cost
4. **Efficient Storage**: Direct mapping access for O(1) earnings lookups