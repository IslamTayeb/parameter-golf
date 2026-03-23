# Implementation Status

This note maps the full research plan to current execution status.

Status labels:

- `done` = implemented and meaningfully checked
- `screened` = short-run result exists, but not yet promoted to a final stack
- `pending` = not started yet
- `blocked` = depends on an earlier item or a stronger base model

## Strict 1xH100 checks

| Item | Status | Notes |
|---|---|---|
| official naive baseline snapshot | `done` | strict `600s` run finished on Hyperbolic |
| current best stack (`fa3 + fused`) | `done` | strict `600s` run finished on Hyperbolic |

## Phase 1 - Architecture + Training

| Item | Status | Notes |
|---|---|---|
| int5/int6 + zstd-22 | `pending` | not started yet |
| 11L + 3x MLP | `screened` | isolated `60s` screen looked bad |
| XSA on last 4 layers | `pending` | env-gated support being added for screening |
| orthogonal init | `pending` | env-gated support being added for screening |
| Muon weight decay | `pending` | env-gated support being added for screening |
| partial RoPE + LN scale | `pending` | env-gated support being added for screening |
| BigramHash (4096) | `pending` | not implemented yet |
| SmearGate | `pending` | not implemented yet |
| SWA tight | `pending` | not implemented yet |
| sliding window eval | `pending` | not implemented yet |
| Muon momentum 0.99 | `screened` | repeated `60s` screens across 5 seeds still look mildly positive |

## Phase 2 - Systems Throughput

| Item | Status | Notes |
|---|---|---|
| DDP bucket tuning + `static_graph` | `pending` | not started yet |
| Turbo-Muon / 4 NS steps | `screened` | faster at `60s`, but clearly worse early bpb |
| packed QKV | `pending` | not started yet |
| persistent Muon buffer | `pending` | not started yet |
| verify softcap+CE fusion | `pending` | not started yet |
| BF16 cross entropy | `pending` | nanogpt-backed easy systems item; not screened yet |
| async prefetch | `pending` | not started yet |

## Phase 3 - Eval stack

| Item | Status | Notes |
|---|---|---|
| sliding-window eval | `pending` | should wait for a stronger base model |
| SWA / EMA | `pending` | should wait for a stronger base model |
| TTT | `blocked` | depends on a stronger trained stack |
| PPM-C | `blocked` | additive eval-time item after a stronger base model |

## Phase 4 - Other optimizer work

| Item | Status | Notes |
|---|---|---|
| Mousse | `pending` | high-effort, lower-priority optimizer idea |

## Current guidance

- Keep using `60s` screens for new ideas.
- For pure hyperparameter ideas, require repeated short screens before any future
  `600s` promotion.
- Focus next on the first cheap code-change batch:
  - orthogonal init
  - Muon weight decay
  - XSA
  - partial RoPE + LN scale
