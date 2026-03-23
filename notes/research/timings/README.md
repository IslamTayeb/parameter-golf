# Timing Tracker

This directory is the tracked summary layer for benchmark and training timing
work.

## How to use it

- Keep raw local command outputs and full logs under `logs/`.
- Record the important numbers and the lesson in
  `notes/research/timings/run-log.md`.
- Use one row per run or per run variant when the numbers are worth preserving.

## What each logged run should include

- date
- provider / hardware
- run type (`strict`, `research_60s`, `systems_sweep`, etc.)
- key config knobs
- train wallclock cap
- stop step
- `step_avg`
- final exact `val_bpb` when available
- source log or source note
- one-line takeaway

## Promotion rule

- `600s` runs are for:
  - strict naive baseline checks
  - strict best-stack checks
  - serious promoted candidates
- `60s` runs are the default for new ideas.
- For pure hyperparameter ideas, require many short repeats before spending a
  full `600s` run on them.
- A good default is to treat one `600s` budget as roughly ten `60s` screens for
  hyperparameter-only exploration.

## Current raw log locations

- `logs/hyperbolic_strict/`
- `logs/research_1xh100/`
- `logs/hyperbolic_1xh100/`
- `logs/runpod_1xh100/`
- `logs/aws_l40s/`

Tracked JSON summaries live under:

- `notes/research/timings/data/`

These are local, richer than the note summaries, and are the first place to go
when a number in the tracker needs to be verified.
