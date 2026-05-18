# Verifiable Agent Memory Demo

This walkthrough presents the repo as an observability layer for AI agent
decision traces.

![Verifiable agent memory demo](assets/screenshots/agent-memory-demo.png)

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Agent as Agent Runtime
    participant SDK as Python SDK
    participant Store as Off-chain Trace Store
    participant Contract as Attestor Contract
    participant Reviewer as Reviewer

    Agent->>SDK: create typed trace
    SDK->>Store: persist full trace
    SDK->>Contract: publish trace hash + metadata
    Reviewer->>Store: retrieve trace
    Reviewer->>Contract: load commitment
    Reviewer-->>Reviewer: hash trace and compare
```

## Entity Graph

```mermaid
erDiagram
    AGENT ||--o{ TRACE : produces
    TRACE ||--o{ REASONING_STEP : contains
    TRACE ||--|| DECISION : ends_with
    TRACE ||--|| TRACE_HASH : commits_to
    TRACE_HASH ||--|| ATTESTATION : stores
    ATTESTATION ||--|| VERIFICATION_RESULT : checks

    TRACE {
      string agent_id
      string model_id
      string reason_code
    }
    ATTESTATION {
      bytes32 trace_hash
      int index
      datetime committed_at
    }
```

## Flow Chart

```mermaid
flowchart LR
    A[Agent input snapshot] --> B[Reasoning trace]
    B --> C[Decision object]
    C --> D[Hash trace]
    D --> E[Publish attestation]
    B --> F[Off-chain trace store]
    F --> G[Reviewer loads trace]
    E --> H[Reviewer loads commitment]
    G --> I[Verify hash match]
    H --> I
```

## Sample Verification Result

```json
{
  "agent_id": "risk-agent/v1",
  "trace_id": "risk-agent/v1#42",
  "reason_code": "scheduled_rebalance",
  "on_chain_index": 42,
  "trace_hash": "0xabc...",
  "match": true
}
```
