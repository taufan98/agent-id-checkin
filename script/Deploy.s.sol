// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentCheck} from "../src/AgentCheck.sol";

/// @notice Deploys AgentCheck against the Agent ID registry.
/// @dev Usage: forge script script/Deploy.s.sol --rpc-url <RPC> --broadcast
///      Registry (BSC mainnet): 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
contract Deploy is Script {
    address public constant AGENT_ID_REGISTRY =
        0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (AgentCheck) {
        vm.startBroadcast();
        AgentCheck check = new AgentCheck(AGENT_ID_REGISTRY);
        vm.stopBroadcast();
        console.log("AgentCheck deployed at:", address(check));
        console.log("Agent ID registry:", AGENT_ID_REGISTRY);
        return check;
    }
}
