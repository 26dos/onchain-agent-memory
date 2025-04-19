// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {AgentRegistry} from "../AgentRegistry.sol";
import {MemoryAttestor} from "../MemoryAttestor.sol";

contract MemoryAttestorTest is Test {
    AgentRegistry registry;
    MemoryAttestor attestor;
    bytes32 constant AGENT = keccak256("agent");

    function setUp() public {
        registry = new AgentRegistry();
        attestor = new MemoryAttestor(registry);
        registry.register(AGENT, bytes32(0));
    }

    function test_attest_increments_index() public {
        uint64 i0 = attestor.attest(AGENT, bytes32("h0"), bytes32("d0"), 1);
        uint64 i1 = attestor.attest(AGENT, bytes32("h1"), bytes32("d1"), 1);
        assertEq(i0, 0);
        assertEq(i1, 1);
    }

    function test_attest_reverts_for_non_operator() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(MemoryAttestor.NotOperator.selector);
        attestor.attest(AGENT, bytes32(0), bytes32(0), 1);
    }

    function test_attest_reverts_when_deactivated() public {
        registry.deactivate(AGENT);
        vm.expectRevert(MemoryAttestor.InactiveAgent.selector);
        attestor.attest(AGENT, bytes32(0), bytes32(0), 1);
    }
}



    function testFuzz_attest_increments_monotonically(
        bytes32 traceHash, bytes32 inputDigest, uint32 modelVersion, uint8 count
    ) public {
        vm.assume(count > 0 && count < 32);
        for (uint8 i = 0; i < count; i++) {
            uint64 idx = attestor.attest(AGENT, traceHash, inputDigest, modelVersion, bytes32(0));
            assertEq(idx, i);
        }
    }
