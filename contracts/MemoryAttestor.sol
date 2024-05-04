// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {AgentRegistry} from "./AgentRegistry.sol";

/// @title MemoryAttestor
/// @notice Records cryptographic commitments to agent decisions. Each
/// attestation is a hash over the off-chain reasoning trace; the chain
/// stores the hash + minimal metadata so consumers can verify a trace
/// they later receive.
contract MemoryAttestor {
    AgentRegistry public immutable registry;

    struct Attestation {
        bytes32 traceHash;
        bytes32 inputDigest;
        uint64 timestamp;
        uint32 modelVersion;
    }

    /// agentId => attestation index (monotonic) => attestation
    mapping(bytes32 => mapping(uint64 => Attestation)) public attestations;
    mapping(bytes32 => uint64) public nextIndex;

    event Attested(
        bytes32 indexed agentId,
        uint64 indexed index,
        bytes32 traceHash,
        bytes32 inputDigest,
        uint32 modelVersion
    );

    error NotOperator();
    error InactiveAgent();

    constructor(AgentRegistry _registry) {
        registry = _registry;
    }

    function attest(
        bytes32 agentId,
        bytes32 traceHash,
        bytes32 inputDigest,
        uint32 modelVersion
    ) external returns (uint64 index) {
        (address operator,, , bool active) = registry.agents(agentId);
        if (msg.sender != operator) revert NotOperator();
        if (!active) revert InactiveAgent();

        index = nextIndex[agentId];
        attestations[agentId][index] = Attestation({
            traceHash: traceHash,
            inputDigest: inputDigest,
            timestamp: uint64(block.timestamp),
            modelVersion: modelVersion
        });
        unchecked {
            nextIndex[agentId] = index + 1;
        }
        emit Attested(agentId, index, traceHash, inputDigest, modelVersion);
    }
}
