// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUSDT.sol";

/// @title TreeVibe - Payment system with real-time earnings tracking
/// @notice Tracks total and weekly earnings for users with leaderboard integration
contract TreeVibe {
    MockUSDT public usdtToken;
    address public owner;
    
    // Earnings tracking
    mapping(address => uint256) public totalEarnings;
    mapping(address => uint256) public weeklyEarnings;
    
    // Weekly reset mechanism
    uint256 public lastWeekReset;
    uint256 public constant WEEK_DURATION = 7 days;
    
    // Events
    event PaymentMade(address indexed user, uint256 amount);
    event WeeklyEarningsReset();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _usdtToken) {
        usdtToken = MockUSDT(_usdtToken);
        owner = msg.sender;
        lastWeekReset = block.timestamp;
    }
    
    /// @notice Pay a user and update their earnings in real-time
    /// @param user Address of the user to pay
    /// @param amount Amount to pay in USDT (6 decimals)
    function payUser(address user, uint256 amount) external {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be positive");
        
        // Transfer USDT from sender to user
        require(usdtToken.transferFrom(msg.sender, user, amount), "Transfer failed");
        
        // Update earnings in real-time
        totalEarnings[user] += amount;
        weeklyEarnings[user] += amount;
        
        emit PaymentMade(user, amount);
    }
    
    /// @notice Get user earnings data (for leaderboard compatibility)
    /// @param user Address of the user
    /// @return total Total lifetime earnings
    /// @return weekly Current week earnings
    function userOf(address user) external view returns (uint256 total, uint256 weekly) {
        return (totalEarnings[user], weeklyEarnings[user]);
    }
    
    /// @notice Reset weekly earnings for all users (administrative function)
    /// @dev This function should be called at the beginning of each week
    function resetWeeklyEarnings() external onlyOwner {
        require(block.timestamp >= lastWeekReset + WEEK_DURATION, "Too early to reset");
        
        lastWeekReset = block.timestamp;
        // Note: In a production system, you would need to track all users
        // For this implementation, we'll reset specific users as needed
        
        emit WeeklyEarningsReset();
    }
    
    /// @notice Reset weekly earnings for a specific user (gas efficient)
    /// @param user Address of the user to reset
    function resetUserWeeklyEarnings(address user) external onlyOwner {
        weeklyEarnings[user] = 0;
    }
    
    /// @notice Reset weekly earnings for multiple users (batch operation)
    /// @param users Array of user addresses to reset
    function batchResetWeeklyEarnings(address[] calldata users) external onlyOwner {
        require(block.timestamp >= lastWeekReset + WEEK_DURATION, "Too early to reset");
        
        for (uint256 i = 0; i < users.length; i++) {
            weeklyEarnings[users[i]] = 0;
        }
        
        lastWeekReset = block.timestamp;
        emit WeeklyEarningsReset();
    }
    
    /// @notice Get time until next allowed weekly reset
    /// @return seconds Time in seconds until reset is allowed
    function timeUntilReset() external view returns (uint256) {
        uint256 nextReset = lastWeekReset + WEEK_DURATION;
        if (block.timestamp >= nextReset) {
            return 0;
        }
        return nextReset - block.timestamp;
    }
    
    /// @notice Transfer ownership of the contract
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}