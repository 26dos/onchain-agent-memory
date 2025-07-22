"""Example: batch up many traces and commit them via merkle root."""
import os
from datetime import datetime, timezone

from onchain_memory import (
    BatchClient, Trace, InputSnapshot, Decision, ReasoningStep,
)


def make_trace(i: int) -> Trace:
    return Trace(
        agent_id="example/batched-v1",
        model_id="rule-v1",
        input=InputSnapshot(prices={"ETH": 2000.0 + i}),
        steps=[ReasoningStep(role="rule", content=f"tick {i}")],
        decision=Decision(kind="hold"),
    )


def main():
    traces = [make_trace(i) for i in range(64)]
    client = BatchClient(
        rpc_url=os.environ.get("RPC_URL", "http://localhost:8545"),
        batch_attestor_address=os.environ["BATCH_ATTESTOR"],
        private_key=os.environ["AGENT_KEY"],
    )
    receipt = client.publish_batch("example/batched-v1", traces)
    print(f"committed root {receipt['root']} in tx {receipt['tx_hash']}")
    print(f"proof for trace 17:", client.proof_for(traces, 17))


if __name__ == "__main__":
    main()
