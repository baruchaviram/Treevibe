// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUSDT.sol";

/// @title Treevibe - MLM/Referral System with Data Export Capability
/// @notice A decentralized referral system with hierarchical structure and data export functionality
contract Treevibe {
    MockUSDT public immutable usdtToken;

    // User structure
    struct User {
        address account;        // Ethereum wallet address
        uint256 userId;         // Unique user ID
        uint256 uplineId;       // Reference to upline user ID (0 for root users)
        bool isActive;          // User activity status
        uint256 expirationDate; // User expiration timestamp
        uint256 totalEarnings;  // Total earnings accumulated
        uint256 registrationDate; // When user was registered
        uint256[] downlineIds;  // Array of downline user IDs
    }

    // Storage
    mapping(uint256 => User) public users;
    mapping(address => uint256) public accountToUserId;
    uint256 public nextUserId = 1;
    uint256 public totalUsers;

    // Export functionality
    bool public exportExecuted = false;
    address public owner;

    // Events
    event UserRegistered(uint256 indexed userId, address indexed account, uint256 indexed uplineId);
    event UserActivated(uint256 indexed userId, uint256 expirationDate);
    event UserDeactivated(uint256 indexed userId);
    event EarningsAdded(uint256 indexed userId, uint256 amount);
    event DataExported(address indexed caller, uint256 timestamp, uint256 totalUsersExported);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier userExists(uint256 userId) {
        require(users[userId].account != address(0), "User does not exist");
        _;
    }

    constructor(address usdtAddress) {
        require(usdtAddress != address(0), "ZERO_ADDRESS");
        usdtToken = MockUSDT(usdtAddress);
        owner = msg.sender;

        // יצירת משתמש ראשי (root) עם userId = 1
        users[nextUserId] = User({
            account: msg.sender,
            userId: nextUserId,
            uplineId: 0,
            isActive: true,
            expirationDate: 0,
            totalEarnings: 0,
            registrationDate: block.timestamp,
            downlineIds: new uint256[](0)
        });
        accountToUserId[msg.sender] = nextUserId;
        emit UserRegistered(nextUserId, msg.sender, 0);
        nextUserId++;
        totalUsers++;
    }

    /// @notice Register a new user in the system
    /// @param account The Ethereum address of the user
    /// @param uplineId The ID of the upline user (0 for root user)
    /// @return userId The assigned user ID
    function registerUser(address account, uint256 uplineId) external onlyOwner returns (uint256 userId) {
        require(account != address(0), "Invalid address");
        require(accountToUserId[account] == 0, "Address already registered");

        if (uplineId != 0) {
            require(users[uplineId].account != address(0), "Upline does not exist");
        }

        userId = nextUserId++;
        totalUsers++;

        users[userId] = User({
            account: account,
            userId: userId,
            uplineId: uplineId,
            isActive: false,
            expirationDate: 0,
            totalEarnings: 0,
            registrationDate: block.timestamp,
            downlineIds: new uint256[](0)
        });

        accountToUserId[account] = userId;

        // Add to upline's downline array
        if (uplineId != 0) {
            users[uplineId].downlineIds.push(userId);
        }

        emit UserRegistered(userId, account, uplineId);
    }

    /// @notice Activate a user with expiration date
    /// @param userId The user ID to activate
    /// @param expirationDate The expiration timestamp
    function activateUser(uint256 userId, uint256 expirationDate) external onlyOwner userExists(userId) {
        require(expirationDate > block.timestamp, "Expiration must be in future");

        users[userId].isActive = true;
        users[userId].expirationDate = expirationDate;

        emit UserActivated(userId, expirationDate);
    }

    /// @notice Deactivate a user
    /// @param userId The user ID to deactivate
    function deactivateUser(uint256 userId) external onlyOwner userExists(userId) {
        users[userId].isActive = false;
        emit UserDeactivated(userId);
    }

    /// @notice Add earnings to a user
    /// @param userId The user ID
    /// @param amount The earnings amount to add
    function addEarnings(uint256 userId, uint256 amount) external onlyOwner userExists(userId) {
        users[userId].totalEarnings += amount;
        emit EarningsAdded(userId, amount);
    }

    /// @notice Get user downline IDs
    /// @param userId The user ID
    /// @return Array of downline user IDs
    function getUserDownlines(uint256 userId) external view userExists(userId) returns (uint256[] memory) {
        return users[userId].downlineIds;
    }

    /// @notice Check if user is currently active (not expired)
    /// @param userId The user ID
    /// @return True if user is active and not expired
    function isUserCurrentlyActive(uint256 userId) external view userExists(userId) returns (bool) {
        return users[userId].isActive && (users[userId].expirationDate == 0 || block.timestamp <= users[userId].expirationDate);
    }

    // ============ DATA EXPORT FUNCTIONALITY ============

    /// @notice Structure for exported user data
    struct ExportedUser {
        uint256 userId;
        address account;
        uint256 uplineId;
        bool isActive;
        uint256 expirationDate;
        uint256 totalEarnings;
        uint256 registrationDate;
        uint256[] downlineIds;
    }

    /// @notice Export all user data in a structured format for migration
    /// @dev This function is read-only and does not modify any state
    /// @param oneTimeUse If true, can only be called once
    /// @return exportedUsers Array of all user data
    /// @return exportTimestamp When the export was performed
    /// @return totalExported Total number of users exported
    function exportUserData(bool oneTimeUse) 
        external 
        view 
        returns (
            ExportedUser[] memory exportedUsers, 
            uint256 exportTimestamp, 
            uint256 totalExported
        ) 
    {
        // Check one-time use restriction
        if (oneTimeUse) {
            require(!exportExecuted, "Export already executed");
        }

        exportTimestamp = block.timestamp;
        totalExported = totalUsers;
        exportedUsers = new ExportedUser[](totalUsers);

        uint256 exportIndex = 0;

        // Iterate through all users and collect their data
        for (uint256 i = 1; i < nextUserId; i++) {
            if (users[i].account != address(0)) {
                exportedUsers[exportIndex] = ExportedUser({
                    userId: users[i].userId,
                    account: users[i].account,
                    uplineId: users[i].uplineId,
                    isActive: users[i].isActive,
                    expirationDate: users[i].expirationDate,
                    totalEarnings: users[i].totalEarnings,
                    registrationDate: users[i].registrationDate,
                    downlineIds: users[i].downlineIds
                });
                exportIndex++;
            }
        }
    }

    /// @notice Execute one-time export with state change and event emission
    /// @dev This version actually marks the export as executed and emits an event
    /// @return exportedUsers Array of all user data
    /// @return exportTimestamp When the export was performed
    /// @return totalExported Total number of users exported
    function executeExport() 
        external 
        onlyOwner 
        returns (
            ExportedUser[] memory exportedUsers, 
            uint256 exportTimestamp, 
            uint256 totalExported
        ) 
    {
        require(!exportExecuted, "Export already executed");

        // Mark export as executed
        exportExecuted = true;

        exportTimestamp = block.timestamp;
        totalExported = totalUsers;
        exportedUsers = new ExportedUser[](totalUsers);

        uint256 exportIndex = 0;

        // Iterate through all users and collect their data
        for (uint256 i = 1; i < nextUserId; i++) {
            if (users[i].account != address(0)) {
                exportedUsers[exportIndex] = ExportedUser({
                    userId: users[i].userId,
                    account: users[i].account,
                    uplineId: users[i].uplineId,
                    isActive: users[i].isActive,
                    expirationDate: users[i].expirationDate,
                    totalEarnings: users[i].totalEarnings,
                    registrationDate: users[i].registrationDate,
                    downlineIds: users[i].downlineIds
                });
                exportIndex++;
            }
        }

        // Emit event for transparency
        emit DataExported(msg.sender, exportTimestamp, totalExported);
    }

    /// @notice Get export status
    /// @return True if export has been executed
    function isExportExecuted() external view returns (bool) {
        return exportExecuted;
    }

    /// @notice Gas-efficient way to get user data by batch
    /// @param startUserId Starting user ID for the batch
    /// @param batchSize Number of users to include in this batch
    /// @return batchUsers Array of user data for the specified range
    /// @return nextStartId The next user ID to start from for the next batch (0 if no more)
    function exportUserDataBatch(uint256 startUserId, uint256 batchSize) 
        external 
        view 
        returns (ExportedUser[] memory batchUsers, uint256 nextStartId) 
    {
        require(batchSize > 0 && batchSize <= 100, "Invalid batch size");
        require(startUserId > 0, "Invalid start ID");

        ExportedUser[] memory tempUsers = new ExportedUser[](batchSize);
        uint256 batchIndex = 0;
        uint256 currentId = startUserId;

        // Find users starting from startUserId
        while (batchIndex < batchSize && currentId < nextUserId) {
            if (users[currentId].account != address(0)) {
                tempUsers[batchIndex] = ExportedUser({
                    userId: users[currentId].userId,
                    account: users[currentId].account,
                    uplineId: users[currentId].uplineId,
                    isActive: users[currentId].isActive,
                    expirationDate: users[currentId].expirationDate,
                    totalEarnings: users[currentId].totalEarnings,
                    registrationDate: users[currentId].registrationDate,
                    downlineIds: users[currentId].downlineIds
                });
                batchIndex++;
            }
            currentId++;
        }

        // Create the final array with the correct size
        batchUsers = new ExportedUser[](batchIndex);
        for (uint256 i = 0; i < batchIndex; i++) {
            batchUsers[i] = tempUsers[i];
        }

        // Determine next start ID
        nextStartId = currentId < nextUserId ? currentId : 0;
    }

    /// @notice Get basic statistics for export planning
    /// @return totalUsers Total number of registered users
    /// @return nextUserId Next available user ID
    /// @return exportExecuted Whether export has been executed
    function getExportStatistics() external view returns (uint256, uint256, bool) {
        return (totalUsers, nextUserId, exportExecuted);
    }
}
