// AgentCheck configuration.
// Replace CONTRACT_ADDRESS with the deployed contract address after deployment.
const CONFIG = {
  // BSC mainnet (chain ID 56). The dApp runs on the same chain as Agent ID.
  chainId: 56,
  chainName: "BSC Mainnet",
  // TODO: set to the deployed AgentCheck address (leave the zero address until then).
  contractAddress: "0x0000000000000000000000000000000000000000",
  // Agent ID registry (ERC-721, non-transferable) — fixed on BSC mainnet.
  agentIdRegistry: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F",
  abi: [
    "function checkIn()",
    "function getStats(address user) view returns (uint256 total, uint256 streak, uint256 lastDay)",
    "function hasCheckedInToday(address user) view returns (bool)",
    "function participantCount() view returns (uint256)",
    "function getParticipants(uint256 start, uint256 count) view returns (address[])",
    "function totalCheckIns(address) view returns (uint256)",
    "function currentStreak(address) view returns (uint256)",
    "function lastCheckInDay(address) view returns (uint256)",
    "event CheckIn(address indexed user, uint256 indexed day, uint256 streak, uint256 totalCheckIns)",
  ],
  registryAbi: ["function balanceOf(address owner) view returns (uint256)"],
};
