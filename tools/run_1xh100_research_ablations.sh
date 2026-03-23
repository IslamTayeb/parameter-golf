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
NPROC_PER_NODE="${NPROC_PER_NODE:-1}"
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
      "$TORCHRUN_BIN" --standalone --nproc_per_node="$NPROC_PER_NODE" train_gpt.py
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
    mom99)
      run_variant mom99 MUON_MOMENTUM=0.99
      ;;
    ns4)
      run_variant ns4 MUON_BACKEND_STEPS=4
      ;;
    mom99_ns4)
      run_variant mom99_ns4 MUON_MOMENTUM=0.99 MUON_BACKEND_STEPS=4
      ;;
    orthogonal_init)
      run_variant orthogonal_init ORTHOGONAL_INIT=1
      ;;
    muon_wd_002)
      run_variant muon_wd_002 MUON_WEIGHT_DECAY=0.02
      ;;
    muon_wd_004)
      run_variant muon_wd_004 MUON_WEIGHT_DECAY=0.04
      ;;
    xsa4)
      run_variant xsa4 XSA_LAYERS=4
      ;;
    rope50_ln)
      run_variant rope50_ln ROPE_FRACTION=0.5 USE_LN_SCALE=1
      ;;
    bf16_ce)
      run_variant bf16_ce BF16_CE=1
      ;;
    persistent_muon)
      run_variant persistent_muon PERSISTENT_MUON_BUFFER=1
      ;;
    packed_qkv)
      run_variant packed_qkv PACKED_QKV=1
      ;;
    packed_qkv_persistent)
      run_variant packed_qkv_persistent PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1
      ;;
    ddp_static)
      run_variant ddp_static DDP_STATIC_GRAPH=1 DDP_GRADIENT_AS_BUCKET_VIEW=1 DDP_BUCKET_CAP_MB=1
      ;;
    ddp_static_mom99)
      run_variant ddp_static_mom99 DDP_STATIC_GRAPH=1 DDP_GRADIENT_AS_BUCKET_VIEW=1 DDP_BUCKET_CAP_MB=1 MUON_MOMENTUM=0.99
      ;;
    ddp_static_packed_persist)
      run_variant ddp_static_packed_persist DDP_STATIC_GRAPH=1 DDP_GRADIENT_AS_BUCKET_VIEW=1 DDP_BUCKET_CAP_MB=1 PACKED_QKV=1 PERSISTENT_MUON_BUFFER=1
      ;;
    *)
      printf 'Unknown variant: %s\n' "$variant" >&2
      exit 1
      ;;
  esac
done
