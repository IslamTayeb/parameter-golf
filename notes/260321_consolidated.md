# 2026-03-21 - Consolidated Systems Notes for Parameter Golf

This document consolidates and supersedes:

- `notes/260321_execution.md`
- `notes/260321.md`

It is intended to be self-contained enough that both earlier files can be deleted once
this version is reviewed.

It combines four things in one place:

- what was actually changed and benchmarked
- what measurably worked and did not work
- what the current `train_gpt.py` already contains vs. what is still missing
- what the next honest systems-only opportunities appear to be

One important cleanup note: the longer earlier memo referred to an ablation-era snapshot
of `train_gpt.py`, so some line numbers and knob names in that file are now stale.
This consolidated note is the one to trust for current state and interpretation.

## Scope

Throughout this document, "systems-only" means:

- no architecture changes
- no optimizer math changes
- no eval trickery
- no quantization-method changes that alter the learned function
- no assuming a paper-level kernel win transfers directly to this repo without repo evidence

Primary sources combined here:

- direct inspection of the current `train_gpt.py`
- the repo benchmark harness in `tools/benchmark_systems.py`
- benchmark logs in `logs/runpod_1xh100/` and `logs/aws_l40s/`
- the systems run log from March 21
- the broader systems memo / paper review from March 21

## Executive take

- The biggest confirmed systems win in this repo is the input/H2D path fix: `FUSE_BATCH_TRANSFER=1`.
- That win is already landed and now enabled by default.
- `ATTENTION_IMPL=fa3` is real, but it is a secondary win rather than the main story.
- `torch.compile` should stay on.
- The repo is not obviously memory-capacity-bound on H100, so memory-saving papers matter only if they also improve throughput.
- The remaining honest systems-only frontier is mostly low-single-digit engineering work: packed projections, input overlap, DDP tuning, Muon communication cleanup, selective Triton ports, and possibly exact fused tail loss.
- The previous "35-70% compounded systems gain" idea is not evidence-backed for this repo. The one clearly demonstrated large win was the loader transfer change.

## Current code state in `train_gpt.py`

As of the current repo state, the systems-relevant changes break down like this:

| Item | Status | Notes |
|---|---|---|
| `FUSE_BATCH_TRANSFER=1` default | Landed | Main confirmed H100 systems win; now the default path |
| `ATTENTION_IMPL=fa3` support | Landed | Optional, env-gated, useful when FlashAttention is installed |
| `torch.compile` | Landed and effectively required | Current script compiles the Muon backend helper and the model |
| `SKIP_FINAL_EVAL` benchmark escape hatch | Landed | Useful for throughput sweeps |
| Packed QKV projection | Not landed | Attention still uses separate Q, K, V projections |
| Separate-stream / double-buffered batch prefetch | Not landed | Loader is still synchronous |
| DDP `static_graph=True` / `gradient_as_bucket_view=True` | Not landed | DDP still uses the conservative default constructor |
| Persistent Muon flat buffer | Not landed | `updates_flat` is reallocated every optimizer step |
| Exact fused `lm_head + softcap + CE` tail | Not landed | Logits are still materialized before softcap and CE |
| Selected Triton kernel ports | Not landed | None of the proposed modded-nanogpt ports are in the file yet |

## What changed during the systems execution work

### Code changes that landed

- Added optional FlashAttention support via `ATTENTION_IMPL=fa3`.
- Added the fused batch-transfer path in `DistributedTokenLoader.next_batch` so one local token span is moved to GPU and then sliced into `x` and `y` on-device.
- Kept `SKIP_FINAL_EVAL` as a benchmark-only escape hatch so throughput sweeps do not spend time on final roundtrip eval.
- Cleaned `train_gpt.py` back down after ablations so it keeps only the systems knobs that still matter:
  - `ATTENTION_IMPL`
  - `FUSE_BATCH_TRANSFER`
  - `SKIP_FINAL_EVAL`
- Made `FUSE_BATCH_TRANSFER=1` the default because it was the main measured H100 win.

### Tooling changes that landed

- Added `tools/benchmark_systems.py` for reproducible systems-only sweeps.
- Added `tools/run_1xh100_ablations.sh` as a simple 1xH100 entrypoint.
- Added `tools/run_systems_candidate.sh` to launch the current best systems-only candidate cleanly.
- Added `tools/check_aws_h100_quota.sh` to check whether AWS `p5` / `ml.p5` quota had cleared.
- Trimmed the benchmark matrix down to the only variants that still looked meaningful:
  - original baseline transfer path
  - fused batch transfer
  - `flash-attn`
  - `flash-attn` + fused batch transfer

## What worked

### 1xH100 results

These are the main confirmed H100-side systems results.

| Variant | tail_step_ms | Delta vs baseline | Interpretation |
|---|---:|---:|---|
| baseline | 520.18 | - | Current 1x baseline |
| `FUSE_BATCH_TRANSFER=1` | 332.15 | -36.1% | Biggest confirmed systems win |
| `ATTENTION_IMPL=fa3` | 509.85 | -2.0% | Real, but small by itself |
| `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | 313.38 | -39.8% vs baseline / -5.7% vs fused-transfer | Best measured 1x combo |

Equivalent throughput numbers from the cleaner execution log:

| Variant | tok/s | Delta vs baseline |
|---|---:|---:|
| baseline | 1,007,907 | - |
| `FUSE_BATCH_TRANSFER=1` | 1,578,468 | +56.6% |
| `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | 1,673,037 | +66.0% |

Source files:

- `logs/runpod_1xh100/systems_round6.json`
- `logs/runpod_1xh100/systems_round4.json`
- `logs/runpod_1xh100/systems_round5.json`

### 1xL40S results

The AWS L40S runs matter because they show the H100 loader result is not equally large on slower hardware.

| Variant | tail_step_ms | tok/s | Delta vs baseline |
|---|---:|---:|---:|
| baseline | 1012.35 | 517,892 | - |
| `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | 982.775 | 533,477 | +3.0% |

Interpretation:

- On L40S, compute dominates more and the giant H100 loader win mostly disappears.
- The portable win on slower GPUs looks more like "FlashAttention is mildly useful" than "loader transfer order is everything."

Source files:

- `logs/aws_l40s/aws_l40s_round1.json`
- `logs/aws_l40s/aws_l40s_round2.json`
- `logs/aws_l40s/aws_l40s_round3.json`

## Full numerical summary of what mattered and what did not

Relative changes below are measured against the matched baseline in the same benchmark
round unless noted otherwise. This is the compact "worked vs did not" summary with the
actual numbers preserved.

### H100 summary

| Variant | Rel step ms vs matched baseline | Rel tok/s vs matched baseline | Incremental note | Verdict |
|---|---:|---:|---|---|
| `FUSE_BATCH_TRANSFER=1` | `-36.0%` to `-36.1%` | `+56.4%` to `+56.6%` | Large and repeatable across rounds 5 and 6 | Main confirmed systems win |
| `ATTENTION_IMPL=fa3` | `-1.9%` | `+1.9%` | Small win by itself | Real, but secondary |
| `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | `-39.8%` to `-40.0%` | `+66.0%` to `+66.7%` | About `+5.9%` to `+6.6%` tok/s over fused-transfer alone | Best measured combo |
| `PIN_SHARD_MEMORY=1` on top of fused transfer | effectively `0.0%` | effectively `0.0%` | About `-0.18%` step time / `+0.18%` tok/s vs fused only | Noise |
| `ENABLE_MUON_COMPILE=0` only | `-0.5%` | `+0.5%` | Within noise | Not a meaningful lever |
| `ENABLE_MUON_COMPILE=0` with FA3 | `-0.4%` vs matched baseline | `+0.4%` vs matched baseline | About `+1.5%` slower than FA3 alone | Still not a useful lever |
| `SDPA_BACKEND=cudnn` | `+1.0%` slower | `-1.0%` | Slight regression | Did not help |
| `ENABLE_TORCH_COMPILE=0 ENABLE_MUON_COMPILE=0` | `+46.8%` slower | `-31.9%` | Very large regression | Compile clearly matters |
| `TORCH_COMPILE_MODE=reduce-overhead` | failed | failed | Did not complete the benchmark | Not ready |
| `TORCH_COMPILE_MODE=max-autotune` | failed | failed | Did not complete the benchmark | Not ready |

### L40S summary

| Variant | Rel step ms vs matched baseline | Rel tok/s vs matched baseline | Incremental note | Verdict |
|---|---:|---:|---|---|
| `ENABLE_MUON_COMPILE=0` only | `-0.4%` | `+0.4%` | Within noise | Not a meaningful lever |
| `FUSE_BATCH_TRANSFER=1` | `-0.9%` | `+0.9%` | Tiny compared with H100 | Loader win mostly disappears here |
| `PIN_SHARD_MEMORY=1` on top of fused transfer | effectively `0.0%` | effectively `0.0%` | About `+0.15%` slower / `-0.15%` tok/s vs fused only | Noise |
| `ATTENTION_IMPL=fa3` | `-3.2%` | `+3.3%` | Small but real compute-side win | Main portable L40S gain |
| `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | `-3.6%` short run / `-2.9%` longer confirm | `+3.7%` short run / `+3.0%` longer confirm | Only about `+0.4%` tok/s over FA3 alone in the short run | Best measured L40S combo, but still modest |
| `PIN_SHARD_MEMORY=1` on top of FA3 + fused transfer | `-3.4%` vs matched baseline | `+3.5%` vs matched baseline | About `+0.18%` slower / `-0.18%` tok/s vs FA3 + fused only | Noise |

### Cross-hardware takeaway

- `FUSE_BATCH_TRANSFER=1` is the dominant H100 win but only about a `+0.9%` L40S win on its own.
- `ATTENTION_IMPL=fa3` is a small win on both, but it is much closer to the entire story on L40S than on H100.
- `PIN_SHARD_MEMORY=1` is effectively noise on both H100 and L40S.
- `torch.compile` remains part of the required baseline; turning it off on H100 costs roughly one-third of throughput.
- The loader-path optimization is therefore real but clearly hardware-sensitive.

## Interpretation

### The main bottleneck that was actually found

- The biggest missed systems win in the baseline was input staging and host-to-device transfer behavior.
- The repo's own data does not support the idea that attention kernel choice was the dominant missing optimization.
- The single most important concrete lesson from the runs is: do not split and copy the batch the slow way.

### Why FA3 matters less than the paper headlines suggest

- FlashAttention-3 is a real and worthwhile kernel improvement.
- But the repo-level whole-step improvement is much smaller than the paper-level kernel-speed headlines might imply.
- In this trainer, FA3 is best treated as a second-order improvement layered on top of the input-path fix.

### Why the 1xH100 loader result likely still matters on 8x

- The training loop uses `grad_accum_steps = 8 // world_size`.
- Because gradient accumulation shrinks as `world_size` grows, the per-microstep local token volume does not collapse in the naive way.
- That means the same batch-staging path can still matter on 8xH100; this is not obviously just a 1x artifact.

### Why memory-saving papers are not automatically the right lens here

- The published 8x baseline reports roughly `43.54 ms` step time and only about `10 GiB` peak memory.
- That strongly suggests the current H100 setup is not memory-capacity-bound.
- For this repo, memory-focused techniques are only attractive if they reduce traffic, launches, or end-to-end step time.

### Why an immediate CUDA Graph / PyGraph rewrite is not yet justified

- The model has fixed shapes, so graph-oriented ideas are not crazy in principle.
- But the current repo already uses compile, and the compile-mode experiments that were tried did not look healthy.
- That makes a large graph-capture rewrite premature relative to cheaper, more grounded wins.

### One subtle point about compile

- "Disabling Muon compile was negligible" and "compile matters" are not contradictory.
- The isolated Muon-side toggle was not the lever.
- Disabling the broader compiled training path was clearly harmful.

### Cold-start and wallclock overhead still matter

- The 1xH100 logs show a nontrivial gap between internal `train_time_ms` and total wallclock.
- That means compile/warmup/setup tax still exists and may matter under the contest's external wallclock interpretation.

## What did not pan out

These ideas either measured poorly or were not healthy enough to justify more time right now.

- `PIN_SHARD_MEMORY=1`
- `SDPA_BACKEND=cudnn`
- `TORCH_COMPILE_MODE=reduce-overhead`
- `TORCH_COMPILE_MODE=max-autotune`
- treating FA3 as the primary missed win
- assuming CUDA Graph / PyGraph work is the obvious immediate next step
- expecting paper-level compound gains to transfer directly to this repo

## Paper review, distilled

The earlier memo did a broader paper pass. The practical conclusions are below.

### Relevant as idea sources, but easy to overclaim

| Citation | Repo-specific verdict | Why |
|---|---|---|
| `FlashAttention-3` (`2407.08608`) | Partially confirmed | Real H100 attention win, but measured whole-step repo gain is modest |
| `PyGraph` (`2503.19779`) | Conceptually relevant, not immediate | Fixed shapes make it plausible, but current compile-mode experiments in this repo are not healthy |
| `Liger Kernel` (`2410.10989`) | Potential source of specific kernels | Some operator overlap is real, but the paper headline comes from a different training stack |
| `Turbo-Muon` (`2512.04632`) | Relevant but unproven here | Most credible Muon-speed paper in the set, but still needs repo-specific profiling and validation |
| `CANS` (`2506.10935`) | Relevant but not decisive | Real Muon-adjacent work, but not strong evidence for a large whole-step gain here |

### Not strong direct support for this repo's next systems work

| Citation or category | Repo-specific verdict | Why |
|---|---|---|
| `FP8-LM` (`2310.18313`) | Likely irrelevant near-term | Wrong scale and regime; this model is much smaller and not obviously bottlenecked the same way |
| `ECO` (`2601.22101`) | Likely irrelevant near-term | Primarily a training-memory tradeoff paper, and memory is not the main bottleneck here |
| `DiLoCoX` (`2506.21263`) | Wrong regime | About slow-network distributed training, not fast 8xH100 interconnects |
| MoE systems papers such as `SonicMoE` | Wrong problem | This repo is dense, not MoE |
| Inference fusion papers such as `ClusterFusion` | Wrong workload | Inference latency results do not directly support training-throughput claims here |
| `BinaryAttention` and similar | Unsupported for this use | Wrong domain or too risky to treat as credible systems support for this repo |

Bottom line: papers are useful for scouting ideas, but the repo's own measurements should dominate prioritization.

## Honest next systems-only opportunities

These are the most credible remaining opportunities after accounting for what already landed.

| Priority | Idea | Expected upside | Why it is credible | Main risk |
|---:|---|---|---|---|
| 1 | DDP `static_graph=True` + `gradient_as_bucket_view=True` | ~1-3% on 8x | Static-shape model, tiny diff, low risk | Possible compile/backward edge cases; must validate on real 8x |
| 2 | Packed QKV projection | ~2-5% | Exact math, fewer launches, less memory traffic in a small-width model | GQA split mistakes, state-dict churn |
| 3 | Separate-stream / double-buffered batch prefetch | ~1-4% on top of fused transfer | Natural follow-up to a proven input-path bottleneck | Hidden synchronization and stream-lifetime bugs |
| 4 | Persistent Muon flat buffer and communication cleanup | ~1-4% on 8x | Current optimizer path reallocates and repacks every step | Distributed correctness and update-semantics risk |
| 5 | Port selected safe Triton kernels from modded-nanogpt | low single digits each | Useful candidates exist for Muon and exact `relu^2` MLP fusion | Tuning assumptions may not transfer cleanly to `MODEL_DIM=512` |
| 6 | Exact fused `lm_head + softcap + CE` tail | ~2-5% | Avoids a large logits materialization path | Must preserve exact `softcap * tanh(logits / softcap)` numerics |

Important caveat on Triton/fused loss work:

- Importing an upstream fused softcap CE kernel blindly would not be acceptable if it changes the current exact softcap function.
- This only remains a systems-only change if the current math is preserved exactly.

## Recommended implementation order

If continuing the systems-only pass, this is the recommended order:

1. Revalidate the cleaned baseline on real H100 and then real 8xH100.
2. Use `FUSE_BATCH_TRANSFER=1` as the default baseline.
3. Benchmark `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` on real H100 and 8xH100.
4. Try DDP `static_graph=True` + `gradient_as_bucket_view=True`.
5. Try packed QKV projection.
6. Try separate-stream batch prefetch.
7. Try persistent Muon flat-buffer cleanup.
8. Benchmark safe Triton kernels one by one.
9. Attempt exact fused tail loss only after the lower-risk items are exhausted.

## What not to spend time on first

These do not look like good first bets for this repo:

- `PIN_SHARD_MEMORY=1`
- `SDPA_BACKEND=cudnn`
- `TORCH_COMPILE_MODE=reduce-overhead`
- `TORCH_COMPILE_MODE=max-autotune`
- FP8 training work
- ECO-style training-memory ideas
- BinaryAttention-style ideas
- MoE-specific kernels or papers
- inference-only fusion work
- a full PyGraph-style rewrite before current compile behavior is healthier
- importing non-exact fused softcap kernels

## Realistic upside estimate

- Already confirmed:
  - one large win from fused batch transfer
  - one smaller additional win from FA3
- Still realistically on the table:
  - another 5-15% cumulative throughput improvement if several clean systems wins land well
  - maybe more only if custom kernel or layout work goes unusually well
- Not evidence-backed:
  - another free 35-70% from paper-derived ideas alone

## Practical next run plan

### If H100 access is available

Run the compact matrix again on the cleaned code:

1. original baseline transfer path
2. fused batch transfer
3. `ATTENTION_IMPL=fa3`
4. `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1`

Then run a longer non-record candidate with:

- `FUSE_BATCH_TRANSFER=1`
- `ATTENTION_IMPL=fa3`
- full 80-shard dataset

If that looks good, move to a real fixed-wallclock 8xH100 comparison.

### Infra caution

- Do not set `NCCL_IB_DISABLE=1` on IB/NVLink-capable pods unless there is a very specific reason.
- Another record in this repo explicitly warns that this hurts throughput on the intended fast-interconnect setup, citing roughly `60 ms` vs `44 ms` step time, or about `+36%` slower steps.

## Historical execution context and cloud status

This section preserves the run-log context from March 21 so that the earlier execution note can be deleted without losing operational history. It is historical and may now be stale.

### Hardware used during the March 21 pass

- RunPod 1xH100 pod for the main H100 throughput work; later stopped.
- AWS `g6e.2xlarge` / 1xL40S fallback instance `i-0c9aac5909bc405a7` for slower-GPU validation; later stopped.

### AWS quota requests filed on March 21

- EC2 on-demand P quota to `192` vCPUs for `p5.48xlarge`
  - request id: `74508b0eb3df4a9fb3cf1241f348af35YGDzGmw1`
  - case id: `177412898500246`
  - status at the time: `CASE_OPENED`
- EC2 spot P quota to `192` vCPUs
  - request id: `9667f84b9d1a41229d9f4d9304953f944DoZGLt9`
  - case id: `177412898600531`
  - status at the time: `CASE_OPENED`
- SageMaker `ml.p5.4xlarge` training quota to `1`
  - request id: `92ed645fd3294314a5af2127eda5a6e7el3hwy6A`
  - case id: `177412899300634`
  - status at the time: `CASE_OPENED`
- SageMaker `ml.p5.48xlarge` training quota to `1`
  - request id: `de3d8f9a2e154af7b40b7280a4da78a7JVNslJwA`
  - case id: `177412899300960`
  - status at the time: `CASE_OPENED`

## Bottom line

- The main systems discovery from this work is not "attention kernels are everything."
- It is that the original batch-transfer path was leaving a large amount of H100 throughput on the table.
- After cleanup, the current systems-focused baseline has:
  - one major confirmed win already landed: fused batch transfer by default
  - one smaller optional win already landed: `ATTENTION_IMPL=fa3`
- The next credible gains are not giant paper ports; they are careful, repo-specific engineering improvements.
