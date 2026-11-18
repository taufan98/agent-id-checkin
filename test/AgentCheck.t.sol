// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentCheck} from "../src/AgentCheck.sol";
import {MockAgentIDRegistry} from "../src/mocks/MockAgentIDRegistry.sol";

contract AgentCheckTest is Test {
    MockAgentIDRegistry internal registry;
    AgentCheck internal check;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    event CheckIn(address indexed user, uint256 indexed day, uint256 streak, uint256 totalCheckIns);

    function setUp() public {
        registry = new MockAgentIDRegistry();
        check = new AgentCheck(address(registry));
        registry.setBalance(alice, 1);
        registry.setBalance(bob, 1);
    }

    function test_RevertWhen_NotAgentIdHolder() public {
        address stranger = address(0x5A1D);
        vm.prank(stranger);
        vm.expectRevert(AgentCheck.NotAgentIdHolder.selector);
        check.checkIn();
    }

    function test_CheckInFirstTime() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit CheckIn(alice, block.timestamp / 1 days, 1, 1);
        check.checkIn();

        (uint256 total, uint256 streak, uint256 lastDay) = check.getStats(alice);
        assertEq(total, 1);
        assertEq(streak, 1);
        assertEq(lastDay, block.timestamp / 1 days);
        assertTrue(check.hasCheckedInToday(alice));
        assertEq(check.participantCount(), 1);
    }

    function test_RevertWhen_AlreadyCheckedInToday() public {
        vm.prank(alice);
        check.checkIn();
        vm.prank(alice);
        vm.expectRevert(AgentCheck.AlreadyCheckedInToday.selector);
        check.checkIn();
    }

    function test_StreakIncrementsOnConsecutiveDays() public {
        vm.prank(alice);
        check.checkIn();
        vm.warp(block.timestamp + 1 days);
        assertFalse(check.hasCheckedInToday(alice));
        vm.prank(alice);
        check.checkIn();
        (, uint256 streak,) = check.getStats(alice);
        assertEq(streak, 2);
    }

    function test_StreakResetsAfterGap() public {
        vm.prank(alice);
        check.checkIn();
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        check.checkIn();
        vm.warp(block.timestamp + 3 days); // missed 2 days
        vm.prank(alice);
        check.checkIn();
        (uint256 total, uint256 streak,) = check.getStats(alice);
        assertEq(streak, 1);
        assertEq(total, 3);
    }

    function test_StreakSurvivesSameDayWarpWithinDay() public {
        vm.prank(alice);
        check.checkIn();
        // Warp forward but stay inside the same UTC day: streak must not reset.
        uint256 toDayEnd = (block.timestamp / 1 days + 1) * 1 days - 1;
        vm.warp(toDayEnd);
        vm.prank(alice);
        vm.expectRevert(AgentCheck.AlreadyCheckedInToday.selector);
        check.checkIn();
    }

    function test_ParticipantTracking() public {
        vm.prank(alice);
        check.checkIn();
        vm.prank(bob);
        check.checkIn();
        vm.prank(alice);
        vm.warp(block.timestamp + 1 days);
        check.checkIn(); // second check-in must not duplicate the participant

        assertEq(check.participantCount(), 2);
        assertTrue(check.isParticipant(alice));
        assertTrue(check.isParticipant(bob));
        address[] memory page = check.getParticipants(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0], alice);
        assertEq(page[1], bob);
        // Pagination beyond the end returns an empty array.
        assertEq(check.getParticipants(2, 10).length, 0);
        assertEq(check.getParticipants(1, 10).length, 1);
    }

    function test_RevertWhen_SendingValue() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        (bool ok,) = address(check).call{value: 0.001 ether}(
            abi.encodeWithSignature("checkIn()")
        );
        assertFalse(ok, "checkIn must not accept value");
    }

    function test_GetStatsForNeverCheckedIn() public {
        (uint256 total, uint256 streak, uint256 lastDay) =
            check.getStats(address(0xDEAD));
        assertEq(total, 0);
        assertEq(streak, 0);
        assertEq(lastDay, 0);
        assertFalse(check.hasCheckedInToday(address(0xDEAD)));
    }

    function test_HolderWithMultipleAgentIds() public {
        registry.setBalance(alice, 5); // holding 5 Agent IDs still = 1 check-in/day
        vm.prank(alice);
        check.checkIn();
        vm.prank(alice);
        vm.expectRevert(AgentCheck.AlreadyCheckedInToday.selector);
        check.checkIn();
    }
}
