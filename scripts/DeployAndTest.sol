// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/Treevibe.sol";
import "../contracts/MockUSDT.sol";
import "../test/TreevibeExportTest.sol";

/// @title Simple deployment and test runner
/// @notice Deploys contracts and runs basic validation
contract DeployAndTest {
    event DeploymentComplete(address treevibe, address usdt, address testContract);
    event TestComplete(string testSuite, bool success);
    
    function deployAndRunTests() external {
        // Deploy MockUSDT
        MockUSDT usdt = new MockUSDT();
        
        // Deploy Treevibe
        Treevibe treevibe = new Treevibe(address(usdt));
        
        // Deploy test contract
        TreevibeExportTest testContract = new TreevibeExportTest();
        
        emit DeploymentComplete(address(treevibe), address(usdt), address(testContract));
        
        // Run basic validation
        try testContract.runAllTests() {
            emit TestComplete("All Tests", true);
        } catch {
            emit TestComplete("All Tests", false);
        }
    }
    
    /// @notice Quick validation that contracts are deployed correctly
    function quickValidation() external {
        // Deploy contracts
        MockUSDT usdt = new MockUSDT();
        Treevibe treevibe = new Treevibe(address(usdt));
        
        // Basic validation
        require(treevibe.totalUsers() == 0, "Initial user count should be 0");
        require(treevibe.nextUserId() == 1, "Initial next ID should be 1");
        require(!treevibe.isExportExecuted(), "Export should not be executed initially");
        
        // Test empty export
        (Treevibe.ExportedUser[] memory users, uint256 timestamp, uint256 total) = 
            treevibe.exportUserData(false);
        
        require(users.length == 0, "Empty export should return 0 users");
        require(total == 0, "Total should be 0");
        require(timestamp > 0, "Timestamp should be set");
        
        emit TestComplete("Quick Validation", true);
    }
}