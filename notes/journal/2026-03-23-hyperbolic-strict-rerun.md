# 2026-03-23 - Hyperbolic Strict Rerun

## What happened

- We reran the exact official naive baseline snapshot on a fresh Hyperbolic
  `1x H100 SXM5` box.
- We reran the current full best stack on the same provider with:
  - `ATTENTION_IMPL=fa3`
  - `FUSE_BATCH_TRANSFER=1`
- We also started short `60s` research screens instead of spending full
  `600s` runs on every new idea.

## Strict result

| Variant | Stop step | `step_avg` | Final exact `val_bpb` |
|---|---:|---:|---:|
| official naive baseline snapshot | `1797` | `334.02 ms` | `1.30559449` |
| current best stack (`fa3 + fused`) | `2064` | `290.76 ms` | `1.29478906` |

Derived takeaway:

- best stack beats the strict baseline by about `0.0108 bpb`
- best stack is about `14.9%` faster in tok/s on this provider

Source logs:

- `logs/hyperbolic_strict/strict_naive_260323_0329.log`
- `logs/hyperbolic_strict/strict_best_260323_0343.log`

## Fast research screens

The first `60s` sweep said:

- `11L` alone looked bad
- `3x MLP` alone looked bad
- `11L + 3x MLP` looked much worse
- `MUON_MOMENTUM=0.99` was the first cheap hyperparameter tweak that looked
  slightly positive on both early score and step time
- `MUON_BACKEND_STEPS=4` was faster but clearly worse in early quality

Source logs:

- `logs/research_1xh100/research_260323_0521_control.log`
- `logs/research_1xh100/research_260323_0521_11l.log`
- `logs/research_1xh100/research_260323_0521_mlp3x.log`
- `logs/research_1xh100/research_260323_0521_11l_mlp3x.log`
- `logs/research_1xh100/research_260323_optim_mom99.log`
- `logs/research_1xh100/research_260323_optim_ns4.log`
- `logs/research_1xh100/research_260323_optim_mom99_ns4.log`

## Process lesson

- For pure hyperparameter ideas, a full `600s` confirmation run is usually the
  wrong first move.
- One `600s` budget is often better spent as about ten `60s` screens.
- Only promote a hyperparameter change after repeated short runs say it is real.
