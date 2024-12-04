"""Off-chain merkle helpers for batched attestations.

Pairs with `BatchAttestor.verifyInclusion`. Uses sorted-pair hashing so the
on-chain verifier doesn't need direction bits.
"""
from eth_utils import keccak


def _hash_pair(a: bytes, b: bytes) -> bytes:
    if a < b:
        return keccak(a + b)
    return keccak(b + a)


def merkle_root(leaves: list[bytes]) -> bytes:
    if not leaves:
        return b"\x00" * 32
    layer = list(leaves)
    while len(layer) > 1:
        nxt = []
        for i in range(0, len(layer), 2):
            if i + 1 < len(layer):
                nxt.append(_hash_pair(layer[i], layer[i + 1]))
            else:
                # odd count: duplicate the last hash up
                nxt.append(layer[i])
        layer = nxt
    return layer[0]


def merkle_proof(leaves: list[bytes], index: int) -> list[bytes]:
    if index < 0 or index >= len(leaves):
        raise IndexError("leaf index out of range")
    proof = []
    layer = list(leaves)
    pos = index
    while len(layer) > 1:
        # pair pos with its sibling
        sibling = pos ^ 1
        if sibling < len(layer):
            proof.append(layer[sibling])
        # build next layer
        nxt = []
        for i in range(0, len(layer), 2):
            if i + 1 < len(layer):
                nxt.append(_hash_pair(layer[i], layer[i + 1]))
            else:
                nxt.append(layer[i])
        layer = nxt
        pos //= 2
    return proof
