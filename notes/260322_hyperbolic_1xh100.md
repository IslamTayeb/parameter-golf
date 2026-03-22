# 2026-03-22 - Hyperbolic 1x H100 SXM Follow-Up

This note records the same-day `1x H100 SXM` follow-up after AWS `p5.4xlarge`
quota cleared but on-demand capacity remained unavailable in every tested
`us-east-1` availability zone.

## Why this run happened

- We wanted one honest fixed-wallclock check on an H100-SXM-class box before
  continuing the systems-only branch.
- AWS `p5.4xlarge` was still returning `InsufficientInstanceCapacity` across all
  tested AZs despite the `All P instances = 32` quota approval.
- Hyperbolic had an immediately available `1x H100 SXM5 (80GB)` VM in
  `eu-north-7`, so we used that as the fallback H100-SXM provider.

## Machine and setup

- Provider: Hyperbolic on-demand VM
- Region: `eu-north-7`
- GPU: `1x H100 SXM5 (80GB)`
- CPU / RAM: `32x AMD EPYC`, `185 GB RAM`
- Network: Ethernet
- Disk: `1 TB`
- Python / torch: `Python 3.12`, `torch 2.10.0+cu128`
- Dataset: full `sp1024` FineWeb set downloaded locally on the VM

Local copies of the scored logs were pulled back before any instance teardown:

- `logs/hyperbolic_1xh100/score_1xh100_260322_072951_naive.log`
- `logs/hyperbolic_1xh100/score_1xh100_260322_072951_best.log`
- `logs/hyperbolic_1xh100/score_1xh100_260322_072951_naive.txt`
- `logs/hyperbolic_1xh100/score_1xh100_260322_072951_best.txt`

## What was actually compared

This was **not** a true baseline-vs-full-best-stack comparison.

What we intended to compare:

- baseline: `ATTENTION_IMPL=sdpa FUSE_BATCH_TRANSFER=0`
- full best stack: `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1`

What we actually compared on this VM:

- baseline: `ATTENTION_IMPL=sdpa FUSE_BATCH_TRANSFER=0`
- best available on this machine: `ATTENTION_IMPL=sdpa FUSE_BATCH_TRANSFER=1`

Reason:

- `flash-attn` was not installed on this box.
- `tools/run_1xh100_score_pair.sh` printed:
  - `flash-attn is not installed; falling back to ATTENTION_IMPL=sdpa`
- So the only effective change between the two scored runs was:
  - `FUSE_BATCH_TRANSFER=0 -> 1`

That means this note is a clean check of **baseline vs fused-transfer-only** on
Hyperbolic `1x H100 SXM`, not baseline vs `fa3 + fused`.

## Baseline strictness clarification

- The Hyperbolic run used the repo-root `train_gpt.py` from the current branch,
  not the exact historical baseline snapshot from:
  - `records/track_10min_16mb/2026-03-17_NaiveBaseline/train_gpt.py`
- So the "baseline" run here means:
  - current trainer code
  - `ATTENTION_IMPL=sdpa`
  - `FUSE_BATCH_TRANSFER=0`
- That is enough to prove we did **not** accidentally run the same config twice,
  because the logs show `fuse_batch_transfer:0` vs `fuse_batch_transfer:1`.
- But it is still fairer to describe this as a comparison inside the current
  modified trainer, rather than as an exact rerun of the official naive baseline
  record.
- If we want the strictest possible baseline, we should rerun the exact record
  snapshot file and compare it against a fully working `fa3 + fused` best stack.

## Fixed-wallclock scored results

Both runs used:

- `MAX_WALLCLOCK_SECONDS=600`
- full 80-shard train set
- final quantize-roundtrip eval enabled

| Variant | `ATTENTION_IMPL` | `FUSE_BATCH_TRANSFER` | Stop step | `step_avg` | Final exact `val_bpb` |
|---|---|---:|---:|---:|---:|
| naive baseline | `sdpa` | `0` | `1801` | `333.20 ms` | `1.30554523` |
| best available on this VM | `sdpa` | `1` | `1801` | `333.16 ms` | `1.30572953` |

Derived deltas:

- step time: about `-0.012%`
- tok/s: about `+0.012%`
- final exact `val_bpb`: `+0.00018430` worse

## Interpretation

- On this Hyperbolic `1x H100 SXM` box, `FUSE_BATCH_TRANSFER=1` alone was
  effectively noise.
- This does **not** reproduce the large RunPod `1x H100` loader-path win from
  `notes/260321_consolidated.md`.
- The earlier H100-side loader result should therefore be described as
  **provider/platform-sensitive**, not as a guaranteed "any H100" improvement.
- This run is a negative result for the claim that fused transfer alone buys a
  meaningful fixed-wallclock gain on every H100-SXM-class environment.
- This run is **not** evidence against `ATTENTION_IMPL=fa3`, because `fa3` was
  not actually tested here.

## Practical conclusion

- If we want a true baseline-vs-best-stack H100 comparison, we still need a box
  with working `flash-attn` / `fa3`.
- If we want a true official-proxy systems conclusion, we still ultimately want
  a clean `8x H100 SXM` A/B.
- As of this run, the current systems-only story is weaker than it looked from
  the earlier RunPod `1x H100` numbers alone.

## Fresh-box rerun helpers added during this pass

To make future cloud setup less painful, the following scripts were added:

- `tools/setup_remote_h100.sh`
- `tools/run_1xh100_score_pair.sh`

These scripts are meant to make the next fresh Linux/H100 box setup and scored
`1x` pair rerun much faster.
