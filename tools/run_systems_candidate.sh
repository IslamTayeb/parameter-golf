#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
TORCHRUN_BIN="${TORCHRUN_BIN:-torchrun}"
RUN_ID="${RUN_ID:-systems_candidate_$(date +%y%m%d_%H%M%S)}"

cd "$ROOT_DIR"

if [[ "${DOWNLOAD_DATA:-0}" == "1" ]]; then
  "$PYTHON_BIN" data/cached_challenge_fineweb.py --variant sp1024
fi

env \
  RUN_ID="$RUN_ID" \
  DATA_PATH="${DATA_PATH:-./data/datasets/fineweb10B_sp1024}" \
  TOKENIZER_PATH="${TOKENIZER_PATH:-./data/tokenizers/fineweb_1024_bpe.model}" \
  VOCAB_SIZE="${VOCAB_SIZE:-1024}" \
  ATTENTION_IMPL="${ATTENTION_IMPL:-fa3}" \
  FUSE_BATCH_TRANSFER="${FUSE_BATCH_TRANSFER:-1}" \
  ITERATIONS="${ITERATIONS:-50000}" \
  MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-0}" \
  VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-2000}" \
  TRAIN_LOG_EVERY="${TRAIN_LOG_EVERY:-200}" \
  "$TORCHRUN_BIN" --standalone --nproc_per_node="${NPROC_PER_NODE:-1}" train_gpt.py
