#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cd "$ROOT_DIR"

"$PYTHON_BIN" data/cached_challenge_fineweb.py --variant sp1024 --train-shards "${TRAIN_SHARDS:-1}"

"$PYTHON_BIN" tools/benchmark_systems.py \
  --run-prefix "${RUN_PREFIX:-bench_1xh100}" \
  --variants "${VARIANTS:-baseline,fused_batch_transfer,fa3,fa3_fused_batch_transfer}" \
  "$@"
