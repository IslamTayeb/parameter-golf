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
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s_repeat | control vs `MUON_MOMENTUM=0.99` across 5 seeds | `5x60s` each | `206-208` | control `290.96 ms`, mom99 `290.58 ms` | control `2.091251822`, mom99 `2.087438582` | `notes/research/timings/data/muon-momentum-repeat-2026-03-23.json` | repeated short screens still favor `MUON_MOMENTUM=0.99`, but only modestly |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `ORTHOGONAL_INIT=1` | `60s` | `207` | `290.44 ms` | `2.09883101` | `logs/research_1xh100/research_260323_batch1_orthogonal_init.log` | better pre-quant val, but worse final exact bpb than the matched control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MUON_WEIGHT_DECAY=0.02` | `60s` | `206` | `291.33 ms` | `2.09949172` | `logs/research_1xh100/research_260323_batch1_muon_wd_002.log` | slightly slower and worse than matched control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `MUON_WEIGHT_DECAY=0.04` | `60s` | `206` | `291.40 ms` | `2.09876479` | `logs/research_1xh100/research_260323_batch1_muon_wd_004.log` | also worse than matched control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `XSA_LAYERS=4` | `60s` | `202` | `298.05 ms` | `2.11906917` | `logs/research_1xh100/research_260323_batch1_xsa4.log` | clearly worse on both early score and speed in the first screen |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `ROPE_FRACTION=0.5 USE_LN_SCALE=1` | `60s` | `202` | `298.23 ms` | `2.16055601` | `logs/research_1xh100/research_260323_batch1_rope50_ln.log` | clear negative first screen |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `BF16_CE=1` | `60s` | `207` | `291.10 ms` | `2.09748597` | `logs/research_1xh100/research_260323_batch2_bf16_ce.log` | slightly worse than matched control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `PERSISTENT_MUON_BUFFER=1` | `60s` | `207` | `290.91 ms` | `2.10108798` | `logs/research_1xh100/research_260323_batch2_persistent_muon.log` | slightly worse than matched control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `PACKED_QKV=1` | `60s` | `212` | `284.01 ms` | `2.11164758` | `logs/research_1xh100/research_260323_batch2_packed_qkv.log` | clear speed win but worse quality |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1` | `60s` | `212` | `283.18 ms` | `2.10624569` | `logs/research_1xh100/research_260323_batch2_packed_qkv_persistent.log` | fastest batch-2 variant but still worse than control |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `ORTHOGONAL_INIT=1 MUON_MOMENTUM=0.99` | `60s` | `206` | `291.48 ms` | `2.09992849` | `logs/research_1xh100/research_260323_batch3_orth_mom99.log` | combo did not help |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99` | `60s` | `212` | `282.99 ms` | `2.10529719` | `logs/research_1xh100/research_260323_batch3_packed_persist_mom99.log` | still worse than control despite speed |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | research_60s | `ORTHOGONAL_INIT=1 PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99` | `60s` | `212` | `283.08 ms` | `2.07125597` | `logs/research_1xh100/research_260323_batch3_orth_packed_persist_mom99.log` | strongest short-run combo signal |
| 2026-03-23 | Hyperbolic `1x H100 SXM5` | promoted_600s | `ORTHOGONAL_INIT=1 PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99` | `600s` | `2116` | `283.66 ms` | `1.30109663` | `logs/hyperbolic_strict/candidate_combo_600_260323_0851.log` | faster than strict best stack, but worse final score |

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
- Repeating control vs `MUON_MOMENTUM=0.99` across 5 seeds still favors `0.99`, but the
  edge is small enough that it should be treated as a mild signal, not a lock.
- Orthogonal init is mixed so far: better pre-quant short-run validation but worse final
  exact `val_bpb` in the first screen.
- Muon weight decay at `0.02` and `0.04` does not look good in the first `60s` screens.
- XSA4 and partial-RoPE+LN-scale both looked clearly negative in the first Hyperbolic
  `60s` screens, so they should not be promoted without a stronger reason.
- BF16 cross entropy and persistent Muon buffer each looked slightly worse in their
  first isolated `60s` screens on Hyperbolic.
- Packed QKV gives a real short-run speed win, but the current evidence says that win
  comes with worse quality unless paired with additional changes that we have not yet
  found to hold up at `600s`.
- The strongest `60s` combo signal from the third batch did not survive a `600s`
  confirmation run, so short-run combo wins still need careful promotion discipline.
- `MUON_BACKEND_STEPS=4` improves speed but appears to hurt early quality enough that
  it should not be promoted alone.
- For future hyperparameter-only ideas, the default should be multiple `60s` repeats
  before any `600s` promotion.
