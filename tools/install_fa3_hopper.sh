#!/usr/bin/env bash
set -euo pipefail

VENV_DIR="${VENV_DIR:-$HOME/parameter-golf/.venv}"
FLASH_ATTN_DIR="${FLASH_ATTN_DIR:-$HOME/flash-attention}"
FLASH_ATTN_REF="${FLASH_ATTN_REF:-main}"
CUDA_HOME="${CUDA_HOME:-/usr/local/cuda-12.8}"
MAX_JOBS="${MAX_JOBS:-4}"
NVCC_THREADS="${NVCC_THREADS:-2}"
INSTALL_SYSTEM_PACKAGES="${INSTALL_SYSTEM_PACKAGES:-1}"
LEAN_H100_BUILD="${LEAN_H100_BUILD:-1}"

run_root() {
  if [[ "$(id -u)" == "0" ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ ! -d "$VENV_DIR" ]]; then
  printf 'Missing virtualenv: %s\n' "$VENV_DIR" >&2
  exit 1
fi

if [[ "$INSTALL_SYSTEM_PACKAGES" == "1" ]] && command -v apt-get >/dev/null 2>&1; then
  run_root apt-get update
  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git build-essential ninja-build
fi

if ! command -v ninja >/dev/null 2>&1; then
  printf 'ninja is required on PATH; install ninja-build first\n' >&2
  exit 1
fi

if [[ ! -x "$CUDA_HOME/bin/nvcc" ]]; then
  printf 'Missing nvcc at %s/bin/nvcc\n' "$CUDA_HOME" >&2
  exit 1
fi

if [[ -d "$FLASH_ATTN_DIR/.git" ]]; then
  git -C "$FLASH_ATTN_DIR" fetch --all --prune
  git -C "$FLASH_ATTN_DIR" checkout "$FLASH_ATTN_REF"
  git -C "$FLASH_ATTN_DIR" reset --hard "origin/$FLASH_ATTN_REF"
  git -C "$FLASH_ATTN_DIR" submodule update --init --recursive
else
  git clone --recursive --depth 1 --branch "$FLASH_ATTN_REF" \
    https://github.com/Dao-AILab/flash-attention.git "$FLASH_ATTN_DIR"
fi

"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install einops packaging ninja

(
  cd "$FLASH_ATTN_DIR/hopper"
  rm -rf build dist flash_attn_3.egg-info

  export CUDA_HOME
  export PATH="$VENV_DIR/bin:$CUDA_HOME/bin:$PATH"
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
  export MAX_JOBS
  export NVCC_THREADS

  if [[ "$LEAN_H100_BUILD" == "1" ]]; then
    export FLASH_ATTENTION_DISABLE_SM80=TRUE
    export FLASH_ATTENTION_DISABLE_FP16=TRUE
    export FLASH_ATTENTION_DISABLE_FP8=TRUE
    export FLASH_ATTENTION_DISABLE_HDIM96=TRUE
    export FLASH_ATTENTION_DISABLE_HDIM128=TRUE
    export FLASH_ATTENTION_DISABLE_HDIM192=TRUE
    export FLASH_ATTENTION_DISABLE_HDIM256=TRUE
    export FLASH_ATTENTION_DISABLE_HDIMDIFF64=TRUE
    export FLASH_ATTENTION_DISABLE_HDIMDIFF192=TRUE
    export FLASH_ATTENTION_DISABLE_PAGEDKV=TRUE
    export FLASH_ATTENTION_DISABLE_APPENDKV=TRUE
    export FLASH_ATTENTION_DISABLE_LOCAL=TRUE
    export FLASH_ATTENTION_DISABLE_SOFTCAP=TRUE
    export FLASH_ATTENTION_DISABLE_CLUSTER=TRUE
  fi

  "$VENV_DIR/bin/python" setup.py install
)

"$VENV_DIR/bin/python" -c 'import flash_attn_interface; assert hasattr(flash_attn_interface, "flash_attn_func")'
printf 'FA3 install complete and import check passed\n'
