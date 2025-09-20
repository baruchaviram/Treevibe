// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TreeVibe.sol";

/// @title Leaderboard - Gas-efficient leaderboard using TreeVibe earnings data
/// @notice Provides efficient access to top earners without recalculation
contract Leaderboard {
    TreeVibe public treeVibe;
    
    struct LeaderboardEntry {
        address user;
        uint256 totalEarnings;
        uint256 weeklyEarnings;
    }
    
    constructor(address _treeVibe) {
        treeVibe = TreeVibe(_treeVibe);
    }
    
    /// @notice Get earnings data for a specific user
    /// @param user Address of the user
    /// @return entry LeaderboardEntry with user's earnings
    function getUserEarnings(address user) external view returns (LeaderboardEntry memory entry) {
        (uint256 total, uint256 weekly) = treeVibe.userOf(user);
        return LeaderboardEntry(user, total, weekly);
    }
    
    /// @notice Get earnings data for multiple users (batch query)
    /// @param users Array of user addresses
    /// @return entries Array of LeaderboardEntry structs
    function getBatchUserEarnings(address[] calldata users) external view returns (LeaderboardEntry[] memory entries) {
        entries = new LeaderboardEntry[](users.length);
        
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 total, uint256 weekly) = treeVibe.userOf(users[i]);
            entries[i] = LeaderboardEntry(users[i], total, weekly);
        }
        
        return entries;
    }
    
    /// @notice Compare two users' total earnings
    /// @param userA First user address
    /// @param userB Second user address
    /// @return result -1 if userA < userB, 0 if equal, 1 if userA > userB
    function compareTotalEarnings(address userA, address userB) external view returns (int8) {
        (uint256 totalA, ) = treeVibe.userOf(userA);
        (uint256 totalB, ) = treeVibe.userOf(userB);
        
        if (totalA < totalB) return -1;
        if (totalA > totalB) return 1;
        return 0;
    }
    
    /// @notice Compare two users' weekly earnings
    /// @param userA First user address
    /// @param userB Second user address
    /// @return result -1 if userA < userB, 0 if equal, 1 if userA > userB
    function compareWeeklyEarnings(address userA, address userB) external view returns (int8) {
        (, uint256 weeklyA) = treeVibe.userOf(userA);
        (, uint256 weeklyB) = treeVibe.userOf(userB);
        
        if (weeklyA < weeklyB) return -1;
        if (weeklyA > weeklyB) return 1;
        return 0;
    }
}