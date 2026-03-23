# 1xH100 Sweep Queue

This is the active queue for short `1x H100` research screens.

## Rules

- Default run type: `60s` train wallclock with final eval left on.
- Use full `600s` runs only for:
  - exact baseline checks
  - exact best-stack checks
  - non-hyperparameter candidates that clearly justify promotion
- For pure hyperparameter ideas, spend the equivalent of one `600s` budget on
  repeated `60s` screens first.

## What is already done

### Strict checks

- official naive baseline snapshot: done
- current best stack (`ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1`): done

### Completed `60s` screens

- control (`9L`, `2x MLP`)
- `11L`
- `3x MLP`
- `11L + 3x MLP`
- `MUON_MOMENTUM=0.99`
- `MUON_BACKEND_STEPS=4`
- `MUON_MOMENTUM=0.99 + MUON_BACKEND_STEPS=4`

## Current read from completed screens

- `11L`, `3x MLP`, and `11L + 3x MLP` all looked bad in isolation at `60s`.
- `MUON_MOMENTUM=0.99` is the first cheap hyperparameter change that looked
  modestly positive on both early score and step time.
- `MUON_BACKEND_STEPS=4` was faster but clearly worse in early quality.

## Next ordered queue

### A. Hyperparameter repeats first

Repeat these before promoting any hyperparameter-only change:

1. control vs `MUON_MOMENTUM=0.99` across multiple seeds
2. optional small sweep around momentum if needed:
   - `0.97`
   - `0.99`
   - `0.995`

Promotion rule:

- only promote if the repeated `60s` runs show a stable win on early score and do
  not regress step time materially.

### B. Cheapest code-change screens from the research plan

These are the first real modeling candidates to screen next:

1. orthogonal init
2. Muon weight decay (`0.02`, `0.04`)
3. XSA on last 4 layers
4. partial RoPE + LN scale

Why this order:

- low implementation cost
- strong leaderboard prior
- less byte-risk than quantization and BigramHash work

### C. Next modeling additions after B

Only do these after at least one item from section B looks real:

1. SmearGate
2. BigramHash (`4096` buckets)
3. combined stack of the section-B winners

### D. Eval stack after a promising base model exists

Do not start here first.

1. sliding-window eval
2. SWA during warmdown
3. then only later: TTT / PPM-C

### E. Systems queue after modeling screens

Only do these once the short modeling queue is no longer the highest-return path:

1. BF16 cross entropy (drop `.float()`)
2. packed QKV
3. persistent Muon buffer
4. DDP `static_graph=True` + `gradient_as_bucket_view=True`
5. async prefetch

## Explicit deprioritizations for now

- do not keep rescreening raw `11L` / raw `3x MLP` in isolation
- do not promote `MUON_BACKEND_STEPS=4` on current evidence
- do not spend time on Triton/CUDA kernel work before the cheaper modeling queue
- do not jump into int5/int6 + zstd until we have a stronger base-model direction

## How to record each batch

- save raw logs under `logs/`
- append the important numbers to `notes/research/timings/run-log.md`
- add a journal entry only if the batch changed what we believe
