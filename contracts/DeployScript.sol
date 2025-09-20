// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUSDT.sol";
import "./TreeVibe.sol";
import "./Leaderboard.sol";

/// @title DeployScript - Helper contract for deploying TreeVibe ecosystem
/// @notice This contract can be used to deploy all contracts in the correct order
contract DeployScript {
    MockUSDT public usdtToken;
    TreeVibe public treeVibe;
    Leaderboard public leaderboard;
    
    event ContractsDeployed(
        address indexed usdt,
        address indexed treeVibe,
        address indexed leaderboard
    );
    
    constructor() {
        // Deploy MockUSDT first
        usdtToken = new MockUSDT();
        
        // Deploy TreeVibe with USDT address
        treeVibe = new TreeVibe(address(usdtToken));
        
        // Deploy Leaderboard with TreeVibe address
        leaderboard = new Leaderboard(address(treeVibe));
        
        emit ContractsDeployed(
            address(usdtToken),
            address(treeVibe),
            address(leaderboard)
        );
    }
    
    /// @notice Get all deployed contract addresses
    /// @return usdt MockUSDT contract address
    /// @return treevibe TreeVibe contract address
    /// @return board Leaderboard contract address
    function getContracts() external view returns (address usdt, address treevibe, address board) {
        return (address(usdtToken), address(treeVibe), address(leaderboard));
    }
}