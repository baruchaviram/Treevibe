# Treevibe Data Export Functionality

## Overview
This document describes the data export functionality implemented in the Treevibe contract to enable seamless migration to a new contract in case of failure.

## Features

### 1. Export Data Functionality
The contract provides multiple ways to export user data:

- **`exportUserData(bool oneTimeUse)`**: Exports all user data in a single call
- **`executeExport()`**: One-time export that marks the export as executed and emits an event
- **`exportUserDataBatch(uint256 startUserId, uint256 batchSize)`**: Gas-efficient batch export for large user bases

### 2. Data Structure
Each exported user contains:
- `userId`: Unique user identifier
- `account`: Ethereum wallet address
- `uplineId`: Reference to upline user (0 for root users)
- `isActive`: Current activity status
- `expirationDate`: User expiration timestamp
- `totalEarnings`: Total earnings accumulated
- `registrationDate`: Registration timestamp
- `downlineIds`: Array of downline user IDs

### 3. Security and Transparency
- All export functions are **read-only** (view functions) - they do not modify any state
- `executeExport()` emits a `DataExported` event for transparency
- One-time use protection prevents misuse
- Only owner can execute the state-changing export function

### 4. Gas Optimization
- Batch export functionality for handling large user bases efficiently
- Optimized data structures to minimize gas consumption
- Option to export in chunks rather than all at once

### 5. Usage Examples

#### Export All Data (Read-Only)
```solidity
(ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
    treevibe.exportUserData(false);
```

#### One-Time Export with Event
```solidity
(ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
    treevibe.executeExport(); // Only callable once by owner
```

#### Batch Export for Large Datasets
```solidity
uint256 startId = 1;
uint256 batchSize = 100;

do {
    (ExportedUser[] memory batch, uint256 nextStart) = 
        treevibe.exportUserDataBatch(startId, batchSize);
    
    // Process batch...
    
    startId = nextStart;
} while (startId > 0);
```

#### Check Export Status
```solidity
bool executed = treevibe.isExportExecuted();
(uint256 totalUsers, uint256 nextUserId, bool exportExecuted) = 
    treevibe.getExportStatistics();
```

## Migration Process

1. **Data Export**: Use `executeExport()` to export all user data with event emission
2. **Deploy New Contract**: Deploy the new contract version
3. **Data Import**: Use the exported data to recreate users in the new contract
4. **Validation**: Verify data integrity after import
5. **Transition**: Update frontend/references to point to new contract

## Testing

The implementation includes comprehensive tests in `test/TreevibeExportTest.sol`:

- Basic export functionality validation
- Data integrity verification
- Batch export testing
- One-time use restriction testing
- Gas efficiency validation
- Export statistics verification

## Security Considerations

- Export functions are read-only and cannot modify contract state
- One-time export protection prevents repeated sensitive operations
- Only owner can execute state-changing export functions
- Events provide transparency for all export operations
- Batch limits prevent DOS attacks through oversized requests

## Implementation Details

The export functionality is implemented as part of the main Treevibe contract and includes:

- **3 export methods** for different use cases
- **Comprehensive data validation**
- **Gas optimization techniques**
- **Security safeguards**
- **Event logging for transparency**
- **One-time use protection**

This ensures that user data can be safely and efficiently migrated to a new contract while maintaining data integrity and security.