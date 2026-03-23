# AGENTS.md — Parameter Golf

## What This Is

OpenAI Model Craft Challenge: **Parameter Golf**. A competition to train the best
language model that fits in a **16 MB artifact** (code + compressed model) and trains
in **under 10 minutes on 8xH100s**. Scored by compression on FineWeb validation set
using **bits-per-byte (val_bpb)** — lower is better. The 16 MB cap is decimal
(16,000,000 bytes, not 16 MiB). The challenge runs March 18 – April 30, 2026.

Current SOTA: **1.1428 val_bpb** (see leaderboard in README.md).

## Repository Layout

```
train_gpt.py            # CUDA baseline script (THE file to fork for submissions)
train_gpt_mlx.py        # Apple Silicon MLX variant for local iteration
data/                   # Dataset download scripts and tokenizer specs
  cached_challenge_fineweb.py   # Downloads FineWeb shards from HuggingFace
  tokenizer_specs.json          # Tokenizer configurations
  datasets/                     # Downloaded shard .bin files (gitignored)
  tokenizers/                   # Downloaded tokenizer .model files (gitignored)
records/                # All competition submissions live here
  track_10min_16mb/     # Official leaderboard submissions (10min 8xH100 cap)
  track_non_record_16mb/# Non-record / unlimited-compute submissions
logs/                   # Training run logs and model artifacts (gitignored)
requirements.txt        # Python deps: torch numpy sentencepiece tqdm etc.
```

### Key Files You Edit

- **`train_gpt.py`** — The main training script. Fork this into your submission folder.
  All model architecture, training loop, quantization, and evaluation logic lives in
  this single file.
- Submissions go into `records/track_10min_16mb/YYYY-MM-DD_YourRunName/`.

### Files You Do NOT Edit

- `data/cached_challenge_fineweb.py` — Dataset downloader (use as-is).
- `records/` existing folders — Other people's submissions; read-only reference.
- `README.md` — Leaderboard and rules maintained by OpenAI.

## Setup

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# For MLX (Apple Silicon only): pip install mlx
```

### Download Data

```bash
# Full dataset (80 shards, 8B tokens):
python3 data/cached_challenge_fineweb.py --variant sp1024

# Minimal smoke test (1 shard):
python3 data/cached_challenge_fineweb.py --variant sp1024 --train-shards 1
```

## Run Commands

### Local Smoke Test (MLX / Apple Silicon)

```bash
RUN_ID=smoke ITERATIONS=200 TRAIN_BATCH_TOKENS=8192 VAL_LOSS_EVERY=0 \
  VAL_BATCH_SIZE=8192 python3 train_gpt_mlx.py
```

### Single GPU (CUDA)

```bash
RUN_ID=dev DATA_PATH=./data/datasets/fineweb10B_sp1024 \
  TOKENIZER_PATH=./data/tokenizers/fineweb_1024_bpe.model VOCAB_SIZE=1024 \
  torchrun --standalone --nproc_per_node=1 train_gpt.py
```

### 8xH100 (Official Submission)

```bash
RUN_ID=my_run DATA_PATH=./data/datasets/fineweb10B_sp1024 \
  TOKENIZER_PATH=./data/tokenizers/fineweb_1024_bpe.model VOCAB_SIZE=1024 \
  MAX_WALLCLOCK_SECONDS=600 \
  torchrun --standalone --nproc_per_node=8 train_gpt.py
```

There is no test suite or linter configured. Validation is the `val_bpb` metric
printed at the end of each training run (`final_int8_zlib_roundtrip` lines).

## Current Systems-Only Status

- `train_gpt.py` already includes the main confirmed systems-only wins from the
  March 21-22 pass:
  - `FUSE_BATCH_TRANSFER=1` is the default and was the largest measured H100
    throughput win.
  - `ATTENTION_IMPL=fa3` is supported when `flash-attn` is installed; it is a
    real but secondary win.
  - `SKIP_FINAL_EVAL=1` exists only as a throughput-benchmark escape hatch.
- `torch.compile` remains part of the working baseline. Disabling the broader
  compiled training path was clearly harmful.
- The following ideas were already tried and did not justify keeping in the
  cleaned baseline: `PIN_SHARD_MEMORY=1`, `SDPA_BACKEND=cudnn`, compile mode
  variants such as `reduce-overhead` / `max-autotune`, and disabling Muon
  compile.
- Credible systems-only items that are still not landed: packed QKV, async /
  double-buffered batch prefetch, DDP `static_graph=True` /
  `gradient_as_bucket_view=True`, persistent Muon flat buffer cleanup, exact
  fused `lm_head + softcap + CE`, and selected Triton kernel ports.

## Cloud / Infra Notes

- Prefer AWS EC2 over SageMaker for systems benchmarking. EC2 is closer to the
  bare-instance / RunPod workflow and gives better control over profiling,
  drivers, process launch, storage, and DDP behavior.
- As of 2026-03-22 in `us-east-1`:
  - EC2 on-demand `All P instances` quota is `32`, which is enough for
    `p5.4xlarge` (`1x H100`, `16` vCPUs).
  - EC2 spot `All P Spot Instance Requests` quota is still `0`.
  - SageMaker `ml.p5.4xlarge` and `ml.p5.48xlarge` training quotas are still
    `0`.
  - `p5.48xlarge` (`8x H100`, `192` vCPUs) is still blocked pending a larger
    quota increase.
- Recheck live quota with `tools/check_aws_h100_quota.sh` rather than trusting
  stale notes or support emails alone.
- The competition's final environment is RunPod `H100 SXM`. AWS `p5` is a good
  H100-class proxy for exploration, but small systems wins should still be
  confirmed on RunPod when possible.

## Current Best Run Commands

### 1xH100 compact systems sweep

```bash
python3 data/cached_challenge_fineweb.py --variant sp1024 --train-shards 1
RUN_PREFIX=aws_1xh100_ablate python3 tools/benchmark_systems.py \
  --data-path ./data/datasets/fineweb10B_sp1024 \
  --tokenizer-path ./data/tokenizers/fineweb_1024_bpe.model \
  --variants baseline,fused_batch_transfer,fa3,fa3_fused_batch_transfer
```

### 1xH100 scored naive baseline run

```bash
RUN_ID=aws_naive_1xh100 DATA_PATH=./data/datasets/fineweb10B_sp1024 \
  TOKENIZER_PATH=./data/tokenizers/fineweb_1024_bpe.model VOCAB_SIZE=1024 \
  ATTENTION_IMPL=sdpa FUSE_BATCH_TRANSFER=0 MAX_WALLCLOCK_SECONDS=600 \
  VAL_LOSS_EVERY=0 torchrun --standalone --nproc_per_node=1 train_gpt.py
```

### 1xH100 scored current best systems stack

```bash
RUN_ID=aws_best_1xh100 DATA_PATH=./data/datasets/fineweb10B_sp1024 \
  TOKENIZER_PATH=./data/tokenizers/fineweb_1024_bpe.model VOCAB_SIZE=1024 \
  ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1 MAX_WALLCLOCK_SECONDS=600 \
  VAL_LOSS_EVERY=0 torchrun --standalone --nproc_per_node=1 train_gpt.py
```

### 1xH100 quick research ablations

```bash
RUN_PREFIX=research_1xh100 MAX_WALLCLOCK_SECONDS=60 \
  ./tools/run_1xh100_research_ablations.sh
```

- For new ideas, prefer quick `1x H100` screening runs with about `60s` of
  training wallclock and final eval left on.
- Use these short runs to rank ideas before spending `600s` scored runs on
  them.
- For pure hyperparameter ideas, prefer many short `60s` repeats before
  promoting any winner to a `600s` confirmation run.
- A good default mental model is that one `600s` budget is usually better spent
  as about ten `60s` screens when the only thing changing is hyperparameters.
- Reserve full `10 min` runs for strict baseline checks, best-stack checks, and
  serious candidate configs.

## External Tracking

- `tracker.md` is a local snapshot from an external OpenClaw monitoring instance
  that watches `openai/parameter-golf` for leaderboard movement, PR trends, and
  notable open-PR ideas.
- Treat that OpenClaw feed and `tracker.md` as read-only research context.
  They are useful for prioritization, but not as something to edit in the main
  modeling workflow unless the user explicitly asks.

## Notes Workflow

- `notes/plans/` holds active work. Start there when deciding what to do next.
- `notes/journal/` holds dated checkpoints, reversals, and retrospectives.
- `notes/research/` holds reusable analysis, comparisons, literature, and setup
  guides.
- `notes/archive/` holds stale or superseded scratch material.
- `notes/README.md` defines the stable workflow. Do not turn it into a manual
  file index.
- When work meaningfully changes, update the relevant plan note and add a journal
  entry if the checkpoint is worth preserving.
- Keep raw logs in `logs/`; keep durable summaries in `notes/research/timings/`.

## Hyperparameters

All hyperparameters are set via **environment variables** (see `Hyperparameters` class
at the top of `train_gpt.py`). Key ones:

| Env Var | Default | Purpose |
|---------|---------|---------|
| `ITERATIONS` | 20000 | Max training steps |
| `MAX_WALLCLOCK_SECONDS` | 600 | 10-min wallclock cap (0 = unlimited) |
| `TRAIN_BATCH_TOKENS` | 524288 | Global batch size in tokens |
| `TRAIN_SEQ_LEN` | 1024 | Sequence length |
| `VOCAB_SIZE` | 1024 | Tokenizer vocabulary size |
| `NUM_LAYERS` | 9 | Transformer depth |
| `MODEL_DIM` | 512 | Hidden dimension |
| `NUM_HEADS` / `NUM_KV_HEADS` | 8 / 4 | Attention heads (GQA) |
| `VAL_LOSS_EVERY` | 1000 | Validate every N steps (0 = end only) |

## Code Style

- **Single-file scripts.** `train_gpt.py` contains everything: model, optimizer,
  data loading, quantization, evaluation. Keep it that way for submissions.
- **Python 3.10+** with `from __future__ import annotations`.
- **Type hints** on function signatures using modern syntax (`tuple[...]`, `X | None`).
- **Imports**: stdlib first, then numpy/torch/sentencepiece, grouped by blank lines.
- **Naming**: `snake_case` for functions/variables, `PascalCase` for classes,
  `UPPER_SNAKE_CASE` for constants and env var defaults.
- **Docstrings**: Inline `#` comments preferred over docstrings. Section headers use
  `# ----------` banner comments.
- **No bias** on linear layers by default (`bias=False`).
- **bf16 compute** with fp32 weights stored in `CastedLinear`; small/control params
  kept in fp32 via `restore_low_dim_params_to_fp32`.
- **Error handling**: `raise ValueError(...)` for config validation at init time;
  no try/except in hot paths.

## Architecture Patterns

- **Muon optimizer** for matrix params, Adam for embeddings and scalar params.
- **RMSNorm** (no learned weight), **RoPE**, **GQA** (grouped-query attention).
- **relu^2 MLP** (ReLU then square the output).
- **U-Net skip connections**: encoder half stores activations, decoder half adds them
  back with learned `skip_weights`.
- **Logit softcap**: `softcap * tanh(logits / softcap)` before cross-entropy.
- **Tied embeddings** by default (input and output share `tok_emb.weight`).

## Quantization & Submission Artifact

Post-training: int8 quantization + zlib compression. The pipeline:
1. Per-row int8 for 2D float tensors (matrices).
2. Per-tensor int8 for vectors/scalars.
3. Small tensors (<65536 elements) kept as fp16 passthrough.
4. `zlib.compress(level=9)` on the serialized state dict.
5. Artifact = compressed `.int8.ptz` file + code bytes. Must be < 16,000,000 bytes.

The final `val_bpb` is computed **after** quantize-then-dequantize roundtrip.

## Submission Checklist

Each submission is a PR adding a new folder under `records/track_10min_16mb/`:

```
records/track_10min_16mb/YYYY-MM-DD_RunName/
  README.md          # Explain what you did
  submission.json    # { author, github_id, name, val_bpb, bytes_total, ... }
  train_gpt.py       # Your modified training script (must run standalone)
  train.log          # Training log output (3 runs for statistical significance)
```

### Rules

- Must beat current SOTA by >= 0.005 nats at p < 0.01 (usually 3 runs suffice).
- Train in < 10 min on 8xH100. Eval also < 10 min separately.
- No network calls during eval. Artifact must be self-contained.
- No training on validation data. Test-time training only on already-evaluated tokens.
- Custom tokenizers allowed but scrutinized carefully.
- External packages OK (add requirements.txt to your record folder).

## Competition Tips

- The score metric is `val_bpb` from the `final_int8_zlib_roundtrip` log line.
- Successful approaches so far: int5/int6 quantization, 3x MLP expansion, sliding
  window eval, BigramHash embeddings, SWA, weight decay on Muon, orthogonal init,
  SmearGate, test-time LoRA training, longer sequence lengths.
- Always verify your compressed artifact is under 16,000,000 bytes total.
- The `train_gpt.py` in your records folder must compile and run independently.
