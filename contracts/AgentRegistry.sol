// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

/// @title AgentRegistry
/// @notice Minimal registry mapping agent ids to operator addresses.
/// An agent is a logical actor (e.g. "trading-bot-v3"); the operator is the
/// EOA / contract authorized to publish memory commitments on its behalf.
contract AgentRegistry {
    struct Agent {
        address operator;
        bytes32 modelId;
        uint64 registeredAt;
        bool active;
    }

    mapping(bytes32 => Agent) public agents;

    event AgentRegistered(bytes32 indexed agentId, address indexed operator, bytes32 modelId);
    event AgentDeactivated(bytes32 indexed agentId);

    error AgentExists();
    error NotOperator();

    function register(bytes32 agentId, bytes32 modelId) external {
        if (agents[agentId].operator != address(0)) revert AgentExists();
        agents[agentId] = Agent({
            operator: msg.sender,
            modelId: modelId,
            registeredAt: uint64(block.timestamp),
            active: true
        });
        emit AgentRegistered(agentId, msg.sender, modelId);
    }

    function deactivate(bytes32 agentId) external {
        if (agents[agentId].operator != msg.sender) revert NotOperator();
        agents[agentId].active = false;
        emit AgentDeactivated(agentId);
    }
}
