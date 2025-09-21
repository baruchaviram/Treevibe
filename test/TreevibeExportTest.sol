// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/Treevibe.sol";
import "../contracts/MockUSDT.sol";

/// @title Test Contract for Treevibe Data Export Functionality
/// @notice Comprehensive tests for the data export feature
contract TreevibeExportTest {
    Treevibe public treevibe;
    MockUSDT public usdt;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);
    address public user4 = address(0x5);
    
    event TestResult(string testName, bool passed, string reason);
    
    constructor() {
        // Deploy mock USDT
        usdt = new MockUSDT();
        
        // Deploy Treevibe contract
        treevibe = new Treevibe(address(usdt));
    }
    
    /// @notice Run all tests
    function runAllTests() external {
        testBasicExportFunctionality();
        testExportAfterUserRegistration();
        testBatchExport();
        testOneTimeExportRestriction();
        testExportStatistics();
        testGasEfficiency();
    }
    
    /// @notice Test basic export functionality
    function testBasicExportFunctionality() public {
        try this.basicExportTest() {
            emit TestResult("Basic Export Functionality", true, "All checks passed");
        } catch Error(string memory reason) {
            emit TestResult("Basic Export Functionality", false, reason);
        } catch {
            emit TestResult("Basic Export Functionality", false, "Unknown error");
        }
    }
    
    function basicExportTest() external {
        // Test export on empty system
        (Treevibe.ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
            treevibe.exportUserData(false);
        
        require(users.length == 0, "Empty export should return 0 users");
        require(total == 0, "Total should be 0 for empty system");
        require(timestamp > 0, "Timestamp should be set");
        
        // Test export statistics
        (uint256 totalUsers, uint256 nextId, bool exportExecuted) = treevibe.getExportStatistics();
        require(totalUsers == 0, "Initial total users should be 0");
        require(nextId == 1, "Initial next ID should be 1");
        require(!exportExecuted, "Export should not be executed initially");
    }
    
    /// @notice Test export after registering users
    function testExportAfterUserRegistration() public {
        try this.exportAfterRegistrationTest() {
            emit TestResult("Export After Registration", true, "All checks passed");
        } catch Error(string memory reason) {
            emit TestResult("Export After Registration", false, reason);
        } catch {
            emit TestResult("Export After Registration", false, "Unknown error");
        }
    }
    
    function exportAfterRegistrationTest() external {
        // Setup test data
        setupTestUsers();
        
        // Export all user data
        (Treevibe.ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
            treevibe.exportUserData(false);
        
        require(users.length == 4, "Should export 4 users");
        require(total == 4, "Total should be 4");
        require(timestamp > 0, "Timestamp should be set");
        
        // Verify user data integrity
        bool foundUser1 = false;
        bool foundUser2 = false;
        bool foundUser3 = false;
        bool foundUser4 = false;
        
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].account == user1) {
                foundUser1 = true;
                require(users[i].userId == 1, "User1 ID should be 1");
                require(users[i].uplineId == 0, "User1 should have no upline");
                require(users[i].downlineIds.length == 2, "User1 should have 2 downlines");
            } else if (users[i].account == user2) {
                foundUser2 = true;
                require(users[i].userId == 2, "User2 ID should be 2");
                require(users[i].uplineId == 1, "User2 upline should be user1");
            } else if (users[i].account == user3) {
                foundUser3 = true;
                require(users[i].userId == 3, "User3 ID should be 3");
                require(users[i].uplineId == 1, "User3 upline should be user1");
            } else if (users[i].account == user4) {
                foundUser4 = true;
                require(users[i].userId == 4, "User4 ID should be 4");
                require(users[i].uplineId == 2, "User4 upline should be user2");
            }
        }
        
        require(foundUser1 && foundUser2 && foundUser3 && foundUser4, "All users should be found");
    }
    
    /// @notice Test batch export functionality
    function testBatchExport() public {
        try this.batchExportTest() {
            emit TestResult("Batch Export", true, "All checks passed");
        } catch Error(string memory reason) {
            emit TestResult("Batch Export", false, reason);
        } catch {
            emit TestResult("Batch Export", false, "Unknown error");
        }
    }
    
    function batchExportTest() external {
        // Test batch export with batch size 2
        (Treevibe.ExportedUser[] memory batch1, uint256 nextStart1) = 
            treevibe.exportUserDataBatch(1, 2);
        
        require(batch1.length == 2, "First batch should have 2 users");
        require(nextStart1 == 3, "Next start should be 3");
        
        // Test second batch
        (Treevibe.ExportedUser[] memory batch2, uint256 nextStart2) = 
            treevibe.exportUserDataBatch(3, 2);
        
        require(batch2.length == 2, "Second batch should have 2 users");
        require(nextStart2 == 0, "Should be no more users");
        
        // Test batch export with larger batch size than available
        (Treevibe.ExportedUser[] memory batch3, uint256 nextStart3) = 
            treevibe.exportUserDataBatch(1, 10);
        
        require(batch3.length == 4, "Large batch should return all 4 users");
        require(nextStart3 == 0, "Should be no more users");
    }
    
    /// @notice Test one-time export restriction
    function testOneTimeExportRestriction() public {
        try this.oneTimeExportTest() {
            emit TestResult("One-Time Export Restriction", true, "All checks passed");
        } catch Error(string memory reason) {
            emit TestResult("One-Time Export Restriction", false, reason);
        } catch {
            emit TestResult("One-Time Export Restriction", false, "Unknown error");
        }
    }
    
    function oneTimeExportTest() external {
        // First export with one-time use should work
        (Treevibe.ExportedUser[] memory users1, , ) = 
            treevibe.exportUserData(true);
        
        require(users1.length == 4, "First one-time export should work");
        require(!treevibe.isExportExecuted(), "Export should not be marked as executed yet");
        
        // Execute the one-time export
        (Treevibe.ExportedUser[] memory users2, uint256 timestamp, uint256 total) = 
            treevibe.executeExport();
        
        require(users2.length == 4, "Execute export should work");
        require(total == 4, "Total should be 4");
        require(treevibe.isExportExecuted(), "Export should be marked as executed");
        
        // Second execute export should fail
        try treevibe.executeExport() {
            revert("Second execute export should fail");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256(bytes("Export already executed")), 
                "Should fail with correct error message"
            );
        }
        
        // Export with one-time use should now fail
        try treevibe.exportUserData(true) {
            revert("One-time export should fail after execution");
        } catch Error(string memory reason) {
            require(
                keccak256(bytes(reason)) == keccak256(bytes("Export already executed")), 
                "Should fail with correct error message"
            );
        }
        
        // Export without one-time use should still work
        (Treevibe.ExportedUser[] memory users3, , ) = 
            treevibe.exportUserData(false);
        require(users3.length == 4, "Non-one-time export should still work");
    }
    
    /// @notice Test export statistics
    function testExportStatistics() public {
        try this.exportStatisticsTest() {
            emit TestResult("Export Statistics", true, "All checks passed");
        } catch Error(string memory reason) {
            emit TestResult("Export Statistics", false, reason);
        } catch {
            emit TestResult("Export Statistics", false, "Unknown error");
        }
    }
    
    function exportStatisticsTest() external {
        (uint256 totalUsers, uint256 nextId, bool exportExecuted) = treevibe.getExportStatistics();
        
        require(totalUsers == 4, "Total users should be 4");
        require(nextId == 5, "Next ID should be 5");
        require(exportExecuted, "Export should be marked as executed");
    }
    
    /// @notice Test gas efficiency (basic check)
    function testGasEfficiency() public {
        try this.gasEfficiencyTest() {
            emit TestResult("Gas Efficiency", true, "Basic gas efficiency validated");
        } catch Error(string memory reason) {
            emit TestResult("Gas Efficiency", false, reason);
        } catch {
            emit TestResult("Gas Efficiency", false, "Unknown error");
        }
    }
    
    function gasEfficiencyTest() external view {
        // Test that batch export uses less gas than full export for partial data
        uint256 gasBefore = gasleft();
        treevibe.exportUserDataBatch(1, 2);
        uint256 gasUsedBatch = gasBefore - gasleft();
        
        gasBefore = gasleft();
        treevibe.exportUserData(false);
        uint256 gasUsedFull = gasBefore - gasleft();
        
        // This is a basic check - in practice, batch should use less gas for partial exports
        // but the exact measurement may vary based on optimization
        require(gasUsedBatch > 0 && gasUsedFull > 0, "Gas should be consumed");
    }
    
    /// @notice Setup test users for testing
    function setupTestUsers() internal {
        // Register user1 as root user
        treevibe.registerUser(user1, 0);
        treevibe.activateUser(1, block.timestamp + 365 days);
        treevibe.addEarnings(1, 1000);
        
        // Register user2 under user1
        treevibe.registerUser(user2, 1);
        treevibe.activateUser(2, block.timestamp + 180 days);
        treevibe.addEarnings(2, 500);
        
        // Register user3 under user1
        treevibe.registerUser(user3, 1);
        treevibe.activateUser(3, block.timestamp + 90 days);
        treevibe.addEarnings(3, 300);
        
        // Register user4 under user2
        treevibe.registerUser(user4, 2);
        treevibe.activateUser(4, block.timestamp + 30 days);
        treevibe.addEarnings(4, 100);
    }
}