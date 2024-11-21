// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {AgentRegistry} from "./AgentRegistry.sol";

contract BatchAttestor {
    AgentRegistry public immutable registry;

    struct Batch {
        bytes32 root;
        uint64 timestamp;
        uint64 size;
    }

    mapping(bytes32 => mapping(uint64 => Batch)) public batches;
    mapping(bytes32 => uint64) public nextBatchIndex;

    event BatchAttested(
        bytes32 indexed agentId,
        uint64 indexed batchIndex,
        bytes32 root,
        uint64 size
    );

    error NotOperator();
    error InactiveAgent();

    constructor(AgentRegistry _registry) {
        registry = _registry;
    }

    function attestBatch(
        bytes32 agentId,
        bytes32 root,
        uint64 size
    ) external returns (uint64 index) {
        (address operator, , , bool active) = registry.agents(agentId);
        if (msg.sender != operator) revert NotOperator();
        if (!active) revert InactiveAgent();
        index = nextBatchIndex[agentId];
        batches[agentId][index] = Batch({
            root: root,
            timestamp: uint64(block.timestamp),
            size: size
        });
        unchecked { nextBatchIndex[agentId] = index + 1; }
        emit BatchAttested(agentId, index, root, size);
    }

    function verifyInclusion(
        bytes32 agentId,
        uint64 batchIndex,
        bytes32 traceHash,
        bytes32[] calldata proof
    ) external view returns (bool) {
        bytes32 root = batches[agentId][batchIndex].root;
        if (root == bytes32(0)) return false;
        // a single-leaf tree: root == leaf, proof is empty
        if (proof.length == 0) return root == traceHash;
        bytes32 leaf = traceHash;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 sibling = proof[i];
            leaf = leaf < sibling
                ? keccak256(abi.encodePacked(leaf, sibling))
                : keccak256(abi.encodePacked(sibling, leaf));
        }
        return leaf == root;
    }
}
