#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv}"
TORCHRUN_BIN="${TORCHRUN_BIN:-$VENV_DIR/bin/torchrun}"
PYTHON_BIN="${PYTHON_BIN:-$VENV_DIR/bin/python}"
DATA_PATH="${DATA_PATH:-$ROOT_DIR/data/datasets/fineweb10B_sp1024}"
TOKENIZER_PATH="${TOKENIZER_PATH:-$ROOT_DIR/data/tokenizers/fineweb_1024_bpe.model}"
VOCAB_SIZE="${VOCAB_SIZE:-1024}"
RUN_PREFIX="${RUN_PREFIX:-research_1xh100_$(date +%y%m%d_%H%M%S)}"
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-60}"
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-0}"
ATTENTION_IMPL="${ATTENTION_IMPL:-fa3}"
FUSE_BATCH_TRANSFER="${FUSE_BATCH_TRANSFER:-1}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/logs/research_1xh100}"
VARIANTS="${VARIANTS:-control,11l,mlp3x,11l_mlp3x}"

mkdir -p "$LOG_DIR"

if [[ "$ATTENTION_IMPL" == "fa3" ]]; then
  if ! "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import importlib.util
ok = importlib.util.find_spec("flash_attn") is not None or importlib.util.find_spec("flash_attn_interface") is not None
raise SystemExit(0 if ok else 1)
PY
  then
    printf 'flash-attn is not installed; falling back to ATTENTION_IMPL=sdpa\n' >&2
    ATTENTION_IMPL=sdpa
  fi
fi

run_variant() {
  local short_name="$1"
  shift
  local run_id="${RUN_PREFIX}_${short_name}"
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
      ATTENTION_IMPL="$ATTENTION_IMPL" \
      FUSE_BATCH_TRANSFER="$FUSE_BATCH_TRANSFER" \
      "$@" \
      "$TORCHRUN_BIN" --standalone --nproc_per_node=1 train_gpt.py
  ) 2>&1 | tee "$log_path"

  "$PYTHON_BIN" - "$log_path" <<'PY'
from pathlib import Path
import sys

log_path = Path(sys.argv[1])
lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
step_lines = [line for line in lines if line.startswith("step:")]
score_lines = [line for line in lines if "final_int8_zlib_roundtrip_exact" in line]
summary = []
if step_lines:
    summary.append(step_lines[-1])
if score_lines:
    summary.append(score_lines[-1])
print("\n".join(summary) if summary else f"NO_SUMMARY_FOUND {log_path}")
PY
}

IFS=',' read -r -a variant_list <<< "$VARIANTS"
for variant in "${variant_list[@]}"; do
  case "$variant" in
    control)
      run_variant control NUM_LAYERS=9 MLP_MULT=2
      ;;
    11l)
      run_variant 11l NUM_LAYERS=11 MLP_MULT=2
      ;;
    mlp3x)
      run_variant mlp3x NUM_LAYERS=9 MLP_MULT=3
      ;;
    11l_mlp3x)
      run_variant 11l_mlp3x NUM_LAYERS=11 MLP_MULT=3
      ;;
    *)
      printf 'Unknown variant: %s\n' "$variant" >&2
      exit 1
      ;;
  esac
done
