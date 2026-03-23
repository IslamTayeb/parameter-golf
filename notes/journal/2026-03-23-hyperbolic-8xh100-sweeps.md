# 2026-03-23 - Hyperbolic 8xH100 Sweeps

## Goal

- Use a short-lived `8x H100 SXM5` bare-metal box for fast discovery only.
- Run `60s` train-wallclock screens with final eval left on.
- Promote to `180s` only if a variant clearly beats the matched `60s` control.

## Setup

- Provider: Hyperbolic bare metal
- Region: `us-central-1`
- Hardware: `8x H100 SXM5 (80GB)`
- CPU / RAM: `104x Intel Xeon Platinum 8470`, `1 TB RAM`
- Repo: `/home/ubuntu/parameter-golf`
- Upstream baseline repo: `/home/ubuntu/parameter-golf-openai`
- FA3: installed and working on the box

## 8x reference point

### Official naive baseline snapshot, `60s`

- `step_avg: 43.67 ms`
- final exact `val_bpb: 1.32982923`
- log:
  - `logs/hyperbolic_8xh100/strict8x_naive_260323_1552.log`

### Current best-stack control, `60s`

- config:
  - `ATTENTION_IMPL=fa3`
  - `FUSE_BATCH_TRANSFER=1`
- `step_avg: 38.24 ms`
- final exact `val_bpb: 1.31779916`
- log:
  - `logs/hyperbolic_8xh100/research8x_260323_batch1_control.log`

Relative to the strict naive baseline, the current best-stack control is:

- about `14.2%` faster in tok/s
- about `0.0120 bpb` better on final exact score

## Batch 1 - High-upside systems and hyperparameter screens

| Variant | `step_avg` | Final exact `val_bpb` | Read |
|---|---:|---:|---|
| control | `38.24 ms` | `1.31779916` | current best 8x control |
| `MUON_MOMENTUM=0.99` | `38.18 ms` | `1.32029064` | tiny speed win, worse score |
| DDP static/bucket-view/small-bucket | `43.15 ms` | `1.33135697` | clear loss |
| DDP static + `MUON_MOMENTUM=0.99` | `43.05 ms` | `1.33064462` | still clear loss |
| `PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1` | `38.00 ms` | `1.32519236` | faster, worse score |
| DDP static + packed+persist | `41.78 ms` | `1.33306583` | clear loss |

Takeaways:

- No DDP win on this `8x` box in the tested configuration.
- Packed QKV + persistent buffer buys speed, but not enough quality to beat the
  plain control.
- `MUON_MOMENTUM=0.99` does not transfer cleanly from the `1x` mild signal.

## Batch 2 - Orthogonal-init combinations

| Variant | `step_avg` | Final exact `val_bpb` | Read |
|---|---:|---:|---|
| `ORTHOGONAL_INIT=1` | `38.14 ms` | `1.32213446` | slightly faster, worse score |
| `ORTHOGONAL_INIT=1 MUON_MOMENTUM=0.99` | `38.16 ms` | `1.32117140` | still worse than control |
| `PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99` | `38.03 ms` | `1.32571842` | faster, worse score |
| `ORTHOGONAL_INIT=1 PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99` | `38.02 ms` | `1.32625510` | faster, still worse score |

Takeaways:

- None of the orthogonal-init combinations beat the plain best-stack control.
- The short-run `1x` combo signal did not transfer to `8x`.
- Because no `60s` variant beat the matched control, nothing was promoted to a
  `180s` run.

## Main conclusion

- On this `8x H100` box, the simplest current best stack remains the winner:
  - `ATTENTION_IMPL=fa3`
  - `FUSE_BATCH_TRANSFER=1`
- The more aggressive systems / optimizer combinations were either slower,
  lower-quality, or both.
- The `8x` results reinforce the current conservative conclusion:
  - the extra nanogpt-inspired systems additions are not yet beating the simple
    `fa3 + fused` base in this repo

## Data preservation

All raw logs and machine-readable summaries were copied back locally:

- raw logs:
  - `logs/hyperbolic_8xh100/`
  - `logs/hyperbolic_8xh100_txt/`
- JSON summary:
  - `notes/research/timings/data/hyperbolic-8xh100-2026-03-23.json`
