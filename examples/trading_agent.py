"""Example: a small trading agent that attests every decision on-chain.

Run this against a local anvil node:

  $ anvil --port 8545
  $ forge create contracts/AgentRegistry.sol:AgentRegistry
  $ forge create contracts/MemoryAttestor.sol:MemoryAttestor --constructor-args $AGENT_REGISTRY
  $ ATTESTOR=0x... AGENT_KEY=0x... python examples/trading_agent.py

The trader makes a (fake) buy/sell decision once per "tick", commits the
trace, and prints the on-chain index it was assigned.
"""
import os
import time
from datetime import datetime, timezone

from onchain_memory.client import MemoryClient
from onchain_memory.schema import Trace, InputSnapshot, ReasoningStep, Decision


def make_decision(price: float) -> Trace:
    return Trace(
        agent_id="example/trader-v1",
        model_id="rule-based-v1",
        model_version=1,
        timestamp=datetime.now(timezone.utc),
        input=InputSnapshot(prices={"ETH": price}),
        steps=[
            ReasoningStep(role="rule", content=f"price={price}, threshold=2000"),
            ReasoningStep(role="rule", content="signal: buy" if price < 2000 else "signal: hold"),
        ],
        decision=Decision(kind="buy" if price < 2000 else "hold"),
    )


def main():
    client = MemoryClient(
        rpc_url=os.environ.get("RPC_URL", "http://localhost:8545"),
        attestor_address=os.environ["ATTESTOR"],
        private_key=os.environ["AGENT_KEY"],
    )
    for tick, price in enumerate([1980, 1995, 2010, 2025, 1990]):
        trace = make_decision(price)
        result = client.publish(trace)
        print(f"tick {tick}: decision={trace.decision.kind} -> tx {result['tx_hash']}")
        time.sleep(1)


if __name__ == "__main__":
    main()
