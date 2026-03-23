# Run Log

This is the compact ledger of important timings, scores, and lessons so we do
not have to reconstruct the story from terminal scrollback.

## Promotion policy

- Start with `60s` train-wallclock screens for new ideas.
- If an idea is purely hyperparameter-based, run many short repeats before
  promoting it.
- A good default is to spend a would-be `600s` hyperparameter budget on about
  ten `60s` screens first.
- Only promote clear winners to a full `600s` confirmation run.

## Historical runs

| Date | Provider / HW | Type | Config | Wallclock | Stop step | `step_avg` | Final exact `val_bpb` | Source | Takeaway |
|---|---|---|---|---:|---:|---:|---:|---|---|
| 2026-03-21 | RunPod `1x H100 SXM` | systems_sweep | baseline | n/a | n/a | `520.18 ms` | n/a | `notes/research/systems-consolidated.md` | baseline reference for the first H100 systems pass |
| 2026-03-21 | RunPod `1x H100 SXM` | systems_sweep | `FUSE_BATCH_TRANSFER=1` | n/a | n/a | `332.15 ms` | n/a | `notes/research/systems-consolidated.md` | large H100-side systems win on that provider |
| 2026-03-21 | RunPod `1x H100 SXM` | systems_sweep | `ATTENTION_IMPL=fa3` | n/a | n/a | `509.85 ms` | n/a | `notes/research/systems-consolidated.md` | FA3 alone is real but small |
| 2026-03-21 | RunPod `1x H100 SXM` | systems_sweep | `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | n/a | n/a | `313.38 ms` | n/a | `notes/research/systems-consolidated.md` | best measured 1x systems combo on RunPod |
| 2026-03-21 | AWS `1x L40S` | systems_sweep | baseline | n/a | n/a | `1012.35 ms` | n/a | `notes/research/systems-consolidated.md` | slower-GPU baseline |
| 2026-03-21 | AWS `1x L40S` | systems_sweep | `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | n/a | n/a | `982.775 ms` | n/a | `notes/research/systems-consolidated.md` | only modest gain on L40S |
| 2026-03-22 | Hyperbolic `1x H100 SXM5` | strict_like | `sdpa FUSE_BATCH_TRANSFER=0` | `600s` | `1801` | `333.20 ms` | `1.30554523` | `notes/journal/2026-03-22-hyperbolic-1xh100.md` | current trainer, not exact official baseline snapshot |
| 2026-03-22 | Hyperbolic `1x H100 SXM5` | strict_like | `sdpa FUSE_BATCH_TRANSFER=1` | `600s` | `1801` | `333.16 ms` | `1.30572953` | `notes/journal/2026-03-22-hyperbolic-1xh100.md` | fused transfer alone is noise on this provider |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | strict | official naive baseline snapshot | `600s` | `1797` | `334.02 ms` | `1.30559449` | `logs/hyperbolic_strict/strict_naive_260323_0329.log` | first strict exact-baseline run on Hyperbolic |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | strict | `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1` | `600s` | `2064` | `290.76 ms` | `1.29478906` | `logs/hyperbolic_strict/strict_best_260323_0343.log` | strict best stack beats official baseline by about `0.0108 bpb` |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | control (`9L 2x`, `fa3`, fused) | `60s` | `207` | `290.41 ms` | `2.09289914` | `logs/research_1xh100/research_260323_0521_control.log` | control for the fast research sweep |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `NUM_LAYERS=11` | `60s` | `167` | `359.68 ms` | `2.35323850` | `logs/research_1xh100/research_260323_0521_11l.log` | raw depth increase is much worse in the first minute |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MLP_MULT=3` | `60s` | `189` | `318.80 ms` | `2.16675534` | `logs/research_1xh100/research_260323_0521_mlp3x.log` | raw 3x MLP is also worse at 60s |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `NUM_LAYERS=11 MLP_MULT=3` | `60s` | `143` | `421.41 ms` | `2.51519618` | `logs/research_1xh100/research_260323_0521_11l_mlp3x.log` | raw combined size jump is the worst early result |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MUON_MOMENTUM=0.99` | `60s` | `207` | `289.98 ms` | `2.09084519` | `logs/research_1xh100/research_260323_optim_mom99.log` | small positive on both early score and speed |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MUON_BACKEND_STEPS=4` | `60s` | `210` | `285.98 ms` | `2.16387482` | `logs/research_1xh100/research_260323_optim_ns4.log` | faster but clearly worse early bpb |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MUON_MOMENTUM=0.99 MUON_BACKEND_STEPS=4` | `60s` | `210` | `286.74 ms` | `2.16443051` | `logs/research_1xh100/research_260323_optim_mom99_ns4.log` | no rescue; still worse than control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | promoted_600s | `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1 MUON_MOMENTUM=0.99` | `600s` | cancelled | cancelled | cancelled | `/root/parameter-golf/logs/hyperbolic_strict/candidate_best_mom99_260323_0551.log` | cancelled after deciding pure hyperparameter ideas should get repeated `60s` screens instead |

## Current lessons

- The strict Hyperbolic `fa3 + fused` stack is meaningfully better than the exact
  official naive baseline on the same provider.
- The earlier RunPod loader win is real but provider-sensitive; Hyperbolic did not
  reproduce a meaningful fused-transfer-only win.
- Pure shape scaling (`11L`, `3x MLP`, `11L+3x`) looks bad in the first `60s` on
  Hyperbolic when applied in isolation.
- `MUON_MOMENTUM=0.99` is the first cheap hyperparameter change that looked modestly
  positive on both early score and speed, but it should still be judged by many
  repeated `60s` runs before any future `600s` promotion.
- `MUON_BACKEND_STEPS=4` improves speed but appears to hurt early quality enough that
  it should not be promoted alone.
- For future hyperparameter-only ideas, the default should be multiple `60s` repeats
  before any `600s` promotion.
