// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentCheck} from "../src/AgentCheck.sol";
import {MockAgentIDRegistry} from "../src/mocks/MockAgentIDRegistry.sol";

/// @notice Local smoke test ONLY (anvil). Deploys the mock registry +
///         AgentCheck, grants the broadcaster a mock Agent ID, checks in,
///         and prints the resulting stats. Never use on mainnet.
contract SmokeTest is Script {
    function run() external {
        vm.startBroadcast();
        MockAgentIDRegistry mock = new MockAgentIDRegistry();
        AgentCheck check = new AgentCheck(address(mock));
        mock.setBalance(msg.sender, 1);
        check.checkIn();
        vm.stopBroadcast();

        (uint256 total, uint256 streak, uint256 lastDay) = check.getStats(msg.sender);
        console.log("mock registry:", address(mock));
        console.log("AgentCheck:", address(check));
        console.log("total check-ins:", total);
        console.log("streak:", streak);
        console.log("last day:", lastDay);
        console.log("hasCheckedInToday:", check.hasCheckedInToday(msg.sender));
        console.log("participantCount:", check.participantCount());
    }
}
