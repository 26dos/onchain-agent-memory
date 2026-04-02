<div align="center">

# onchain-agent-memory

**Cryptographic attestation registry for AI agent reasoning traces.**

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=for-the-badge&logo=solidity&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue?style=for-the-badge)

[Install](#install) · [Usage](#usage) · [Contracts](#contracts) · [Lifecycle](docs/lifecycle.md) · [Gas](docs/gas.md)

</div>

---

## Why?

Autonomous agents are starting to take real economic actions on-chain. When
something goes wrong (a bad trade, a failed liquidation, a contested vote),
there is no canonical record of what the agent *actually believed* when it
acted. This repo gives agents a way to commit to their reasoning trace
on-chain, in O(1) gas, so a verifiable record exists later.

The contracts are deliberately minimal: they store `keccak256(trace)` plus
metadata. The trace itself lives off-chain (S3, IPFS, the operator's
database — whatever works). Anyone holding a trace can prove it really is
what the agent committed to.

## Install

```bash
# contracts (foundry)
forge build

# python sdk
cd sdk && pip install -e .
```

## Usage

Producer (agent side):

```python
from onchain_memory import MemoryClient, Trace, InputSnapshot, Decision, ReasoningStep

trace = Trace(
    agent_id="my/trader-v1",
    model_id="claude-sonnet-4-6",
    input=InputSnapshot(prices={"ETH": 2050.0}),
    steps=[ReasoningStep(role="model", content="...")],
    decision=Decision(kind="buy", params={"size_usd": 100}),
)

client = MemoryClient(rpc_url=..., attestor_address=..., private_key=...)
receipt = client.publish(trace, reason_code="rebalance")
```

Consumer (verifier side):

```python
client = MemoryClient(rpc_url=..., attestor_address=...)
result = client.verify(trace, on_chain_index=42)
assert result["match"]
```

## Contracts

| Contract            | Purpose                                                |
|---------------------|--------------------------------------------------------|
| `AgentRegistry`     | Maps agent ids to operator EOAs. Identity layer.       |
| `MemoryAttestor`    | Per-decision attestations. Indexed by `(agentId, idx)`.|
| `BatchAttestor`     | Merkle-root commitments for high-volume agents.        |

Gas costs and the batch-vs-single trade-off are documented in
[docs/gas.md](docs/gas.md). The full attestation lifecycle is in
[docs/lifecycle.md](docs/lifecycle.md).

## License

BSD-3-Clause. See [LICENSE](LICENSE).
