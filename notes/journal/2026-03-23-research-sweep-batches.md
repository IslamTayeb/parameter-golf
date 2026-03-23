# 2026-03-23 - Research Sweep Batches

## What happened

- We converted the research plan into an explicit `1x H100` sweep queue.
- We preserved all Hyperbolic run logs locally and generated tracked JSON dumps.
- We ran multiple `60s` screening batches and then promoted the strongest
  non-hyperparameter combo to a `600s` confirmation run.

## Key results

### Repeated hyperparameter screens

- `MUON_MOMENTUM=0.99` still looked mildly positive across 5 repeated `60s`
  screens versus control.
- The edge was small, so it remains a mild signal rather than a lock.

### Batch 1 - First code-change screens

- `ORTHOGONAL_INIT=1`
  - improved the short-run pre-quant validation line
  - but worsened final exact `val_bpb` in the first screen
- `MUON_WEIGHT_DECAY=0.02` and `0.04`
  - both looked slightly worse than control
- `XSA_LAYERS=4`
  - clearly worse in the first `60s` screen on Hyperbolic
- `ROPE_FRACTION=0.5 USE_LN_SCALE=1`
  - also clearly worse in the first `60s` screen

### Batch 2 - Easy systems/code screens

- `BF16_CE=1`
  - slightly worse than control
- `PERSISTENT_MUON_BUFFER=1`
  - slightly worse than control
- `PACKED_QKV=1`
  - meaningfully faster
  - but clearly worse in early quality and final exact `val_bpb`
- `PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1`
  - the fastest result in the batch
  - still worse than control on final exact `val_bpb`

### Batch 3 - Promising combinations

- `ORTHOGONAL_INIT=1 PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1 MUON_MOMENTUM=0.99`
  - looked excellent in a `60s` screen
  - `step_avg: 283.08 ms`
  - final exact `val_bpb: 2.07125597`

### 600-second confirmation of the best-looking combo

- The promoted combo was:
  - `ORTHOGONAL_INIT=1`
  - `PACKED_QKV=1`
  - `PERSISTENT_MUON_BUFFER=1`
  - `MUON_MOMENTUM=0.99`
  - plus the current best stack baseline of `fa3 + fused`
- `600s` result:
  - `step_avg: 283.66 ms`
  - final exact `val_bpb: 1.30109663`
- Compared with the strict best-stack control:
  - faster by about `2.5%` tok/s
  - worse by about `0.0063 bpb`

## Main lesson

- A strong `60s` signal can still fail at `600s` once the training trajectory has
  time to separate.
- In particular, combinations that improve throughput a lot can still lose on the
  final score if they damage learning dynamics even slightly.

## Where the current best truth stands

- The strongest confirmed `600s` result so far is still the strict best stack:
  - `ATTENTION_IMPL=fa3`
  - `FUSE_BATCH_TRANSFER=1`
- Its exact Hyperbolic result remains:
  - `final_int8_zlib_roundtrip_exact val_bpb: 1.29478906`

## Source data

- `notes/research/timings/data/hyperbolic-1xh100-2026-03-23.json`
- `notes/research/timings/data/muon-momentum-repeat-2026-03-23.json`
