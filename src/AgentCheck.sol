// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentCheck — a free daily check-in for Agent ID holders
/// @notice One free check-in per address per day. Access is gated ON-CHAIN by
///         Agent ID ownership: the caller must hold at least one Agent ID
///         (ERC-721, non-transferable) in the Agent ID registry.
/// @dev No fees, no token transfers, no approvals, no owner, no pause,
///      no mint, no withdraw. The contract holds no funds and has no
///      privileged functions at all. Anyone can read all state.
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentCheck {
    /// @notice The Agent ID registry (ERC-721, non-transferable).
    IAgentIDRegistry public immutable agentIdRegistry;

    /// @notice Length of one check-in day in seconds.
    uint256 public constant DAY = 1 days;

    /// @notice Total check-ins per address.
    mapping(address => uint256) public totalCheckIns;
    /// @notice Current consecutive-day streak per address.
    mapping(address => uint256) public currentStreak;
    /// @notice Day number (block.timestamp / 1 days) of the last check-in.
    mapping(address => uint256) public lastCheckInDay;
    /// @notice True once an address has ever checked in.
    mapping(address => bool) public isParticipant;

    /// @notice All addresses that have ever checked in, in first-seen order.
    address[] private participants;

    /// @notice Emitted on every successful check-in.
    event CheckIn(address indexed user, uint256 indexed day, uint256 streak, uint256 totalCheckIns);

    /// @notice Thrown when the caller holds no Agent ID.
    error NotAgentIdHolder();
    /// @notice Thrown when the caller already checked in today.
    error AlreadyCheckedInToday();

    /// @param _agentIdRegistry Address of the Agent ID registry contract.
    constructor(address _agentIdRegistry) {
        agentIdRegistry = IAgentIDRegistry(_agentIdRegistry);
    }

    /// @notice Check in for today. Free (no value accepted) and limited to
    ///         once per day per address. The caller signs this transaction
    ///         in their own wallet; nothing is executed on their behalf.
    function checkIn() external {
        if (agentIdRegistry.balanceOf(msg.sender) == 0) {
            revert NotAgentIdHolder();
        }
        uint256 day = block.timestamp / DAY;
        // isParticipant guards the day-0 edge case: lastCheckInDay defaults
        // to 0, which equals day 0, so without this a first check-in on
        // day 0 would wrongly look like a duplicate.
        if (isParticipant[msg.sender] && lastCheckInDay[msg.sender] == day) {
            revert AlreadyCheckedInToday();
        }
        if (lastCheckInDay[msg.sender] + 1 == day) {
            currentStreak[msg.sender] += 1;
        } else {
            currentStreak[msg.sender] = 1;
        }
        lastCheckInDay[msg.sender] = day;
        totalCheckIns[msg.sender] += 1;
        if (!isParticipant[msg.sender]) {
            isParticipant[msg.sender] = true;
            participants.push(msg.sender);
        }
        emit CheckIn(msg.sender, day, currentStreak[msg.sender], totalCheckIns[msg.sender]);
    }

    /// @notice True if `user` already checked in today.
    function hasCheckedInToday(address user) external view returns (bool) {
        return isParticipant[user] && lastCheckInDay[user] == block.timestamp / DAY;
    }

    /// @notice (total check-ins, current streak, last check-in day) for `user`.
    function getStats(address user)
        external
        view
        returns (uint256 total, uint256 streak, uint256 lastDay)
    {
        return (totalCheckIns[user], currentStreak[user], lastCheckInDay[user]);
    }

    /// @notice Number of distinct addresses that have ever checked in.
    function participantCount() external view returns (uint256) {
        return participants.length;
    }

    /// @notice Paginated list of participants, in first-seen order.
    function getParticipants(uint256 start, uint256 count)
        external
        view
        returns (address[] memory)
    {
        uint256 total = participants.length;
        if (start >= total) {
            return new address[](0);
        }
        uint256 end = start + count;
        if (end > total) {
            end = total;
        }
        address[] memory slice = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            slice[i - start] = participants[i];
        }
        return slice;
    }
}
