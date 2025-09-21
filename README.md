# Treevibe

A decentralized MLM/referral system with hierarchical user management and data export functionality for seamless contract migration.

## Contract Addresses and Descriptions

| Contract Name | File | Description |
|----------------|------|-------------|
| Treevibe | `contracts/Treevibe.sol` | Main contract managing users, hierarchy, and earnings with data export capability |
| MockUSDT | `contracts/MockUSDT.sol` | Mock USDT token for testing (6 decimals) |

## Features

### Core Functionality
- **User Management**: Register users with unique IDs and wallet addresses
- **Hierarchical Structure**: Track upline/downline relationships
- **Activity Management**: Handle user activation, deactivation, and expiration dates
- **Earnings Tracking**: Monitor total earnings per user

### Data Export Functionality
- **Multiple Export Methods**: Full export, batch export, and one-time export
- **Gas Optimization**: Batch processing for large user bases
- **Security**: Read-only exports with optional one-time use protection
- **Transparency**: Event emission for all export operations
- **Data Integrity**: Comprehensive user data structure preservation

## Quick Start

### Deployment
```solidity
// Deploy MockUSDT
MockUSDT usdt = new MockUSDT();

// Deploy Treevibe
Treevibe treevibe = new Treevibe(address(usdt));
```

### Basic Usage
```solidity
// Register users
treevibe.registerUser(userAddress, uplineId);
treevibe.activateUser(userId, expirationDate);
treevibe.addEarnings(userId, amount);

// Export data
(ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
    treevibe.exportUserData(false);
```

## Documentation

- [Data Export Functionality](docs/DATA_EXPORT.md) - Detailed documentation on export features
- [Test Suite](test/TreevibeExportTest.sol) - Comprehensive tests for all functionality

## Testing

Run the test suite using the provided test contracts:
```solidity
TreevibeExportTest testContract = new TreevibeExportTest();
testContract.runAllTests();
```

## Security Features

- **Owner-only functions** for user management
- **Read-only export functions** that don't modify state
- **One-time export protection** for sensitive operations
- **Event logging** for transparency
- **Input validation** and error handling

This implementation ensures that user data can be safely migrated to a new contract while maintaining all relationships and earnings data.