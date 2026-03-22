#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv}"
TORCHRUN_BIN="${TORCHRUN_BIN:-$VENV_DIR/bin/torchrun}"
PYTHON_BIN="${PYTHON_BIN:-$VENV_DIR/bin/python}"
DATA_PATH="${DATA_PATH:-$ROOT_DIR/data/datasets/fineweb10B_sp1024}"
TOKENIZER_PATH="${TOKENIZER_PATH:-$ROOT_DIR/data/tokenizers/fineweb_1024_bpe.model}"
VOCAB_SIZE="${VOCAB_SIZE:-1024}"
RUN_PREFIX="${RUN_PREFIX:-score_1xh100_$(date +%y%m%d_%H%M%S)}"
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-600}"
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-0}"
BEST_ATTENTION_IMPL="${BEST_ATTENTION_IMPL:-fa3}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/logs/hyperbolic}"

mkdir -p "$LOG_DIR"

if [[ "$BEST_ATTENTION_IMPL" == "fa3" ]]; then
  if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import importlib.util
ok = importlib.util.find_spec("flash_attn") is not None or importlib.util.find_spec("flash_attn_interface") is not None
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'flash-attn is not installed; falling back to ATTENTION_IMPL=sdpa\n' >&2
    BEST_ATTENTION_IMPL=sdpa
  fi
fi

run_and_report() {
  local run_id="$1"
  shift
  local log_path="$LOG_DIR/$run_id.log"

  (
    cd "$ROOT_DIR"
    env \
      RUN_ID="$run_id" \
      DATA_PATH="$DATA_PATH" \
      TOKENIZER_PATH="$TOKENIZER_PATH" \
      VOCAB_SIZE="$VOCAB_SIZE" \
      MAX_WALLCLOCK_SECONDS="$MAX_WALLCLOCK_SECONDS" \
      VAL_LOSS_EVERY="$VAL_LOSS_EVERY" \
      "$@" \
      "$TORCHRUN_BIN" --standalone --nproc_per_node=1 train_gpt.py
  ) 2>&1 | tee "$log_path"

  "$PYTHON_BIN" - "$log_path" <<'PY'
from pathlib import Path
import sys

log_path = Path(sys.argv[1])
score_lines = [line for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines() if "final_int8_zlib_roundtrip" in line]
print(score_lines[-1] if score_lines else f"NO_SCORE_FOUND {log_path}")
PY
}

run_and_report "${RUN_PREFIX}_naive" ATTENTION_IMPL=sdpa FUSE_BATCH_TRANSFER=0
run_and_report "${RUN_PREFIX}_best" ATTENTION_IMPL="$BEST_ATTENTION_IMPL" FUSE_BATCH_TRANSFER=1
