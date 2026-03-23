# 2026-03-22 - Hyperbolic Strict Run + Fast Ablation Plan

## Goal

- Get one strict `1x H100 SXM` comparison using:
  - the exact official naive baseline snapshot
  - the current best systems stack with `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1`
- Start the research-plan ablation pass with short exploratory runs rather than
  spending full 10-minute wallclock on every idea.

## Strict scored pair

### 1. Exact naive baseline

- Repo: `/root/parameter-golf-openai`
- Script:
  - `records/track_10min_16mb/2026-03-17_NaiveBaseline/train_gpt.py`
- Settings:
  - `MAX_WALLCLOCK_SECONDS=600`
  - full dataset
  - final eval on

### 2. Full current best stack

- Repo: `/root/parameter-golf`
- Script:
  - `train_gpt.py`
- Settings:
  - `ATTENTION_IMPL=fa3`
  - `FUSE_BATCH_TRANSFER=1`
  - `MAX_WALLCLOCK_SECONDS=600`
  - full dataset
  - final eval on

## Fast research-plan ablations

Use the current trainer with:

- `ATTENTION_IMPL=fa3`
- `FUSE_BATCH_TRANSFER=1`
- `MAX_WALLCLOCK_SECONDS=60`
- final eval on

Start with the easiest architecture-only changes already supported by env vars:

1. control: `NUM_LAYERS=9 MLP_MULT=2`
2. depth only: `NUM_LAYERS=11 MLP_MULT=2`
3. width only: `NUM_LAYERS=9 MLP_MULT=3`
4. target shape: `NUM_LAYERS=11 MLP_MULT=3`

These do not require editing model code and give the quickest signal on whether
the research-plan direction is worth deeper work.

## Exit condition for this pass

- Save logs locally
- Summarize exact `val_bpb`, step time, and stop step for all runs
- If `11L/3x` does not show promising short-run movement, deprioritize the more
  invasive research-plan changes for now
