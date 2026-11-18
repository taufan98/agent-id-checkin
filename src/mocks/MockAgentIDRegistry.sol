// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Test-only stand-in for the Agent ID registry (only balanceOf matters).
/// @dev Also used by the local smoke-test deploy script. NEVER point the
///      production deployment at this mock — it uses the real registry.
contract MockAgentIDRegistry {
    mapping(address => uint256) public balances;

    function setBalance(address user, uint256 amount) external {
        balances[user] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }
}
