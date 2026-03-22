#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/IslamTayeb/parameter-golf.git}"
REPO_DIR="${REPO_DIR:-$HOME/parameter-golf}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="${VENV_DIR:-$REPO_DIR/.venv}"
INSTALL_SYSTEM_PACKAGES="${INSTALL_SYSTEM_PACKAGES:-1}"
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-0}"
FLASH_ATTN_STRICT="${FLASH_ATTN_STRICT:-0}"
DOWNLOAD_DATA="${DOWNLOAD_DATA:-0}"
DATA_VARIANT="${DATA_VARIANT:-sp1024}"
TRAIN_SHARDS="${TRAIN_SHARDS:-}"
AUTO_SHUTDOWN_MINUTES="${AUTO_SHUTDOWN_MINUTES:-0}"

run_root() {
  if [[ "$(id -u)" == "0" ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ "$AUTO_SHUTDOWN_MINUTES" != "0" ]]; then
  run_root shutdown -h "+$AUTO_SHUTDOWN_MINUTES" "parameter-golf auto-stop"
fi

if [[ "$INSTALL_SYSTEM_PACKAGES" == "1" ]] && command -v apt-get >/dev/null 2>&1; then
  run_root apt-get update
  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git python3-pip python3-venv build-essential
fi

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" fetch --all --prune
  git -C "$REPO_DIR" checkout main
  git -C "$REPO_DIR" pull --ff-only origin main
else
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
fi

"$PYTHON_BIN" -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install -r "$REPO_DIR/requirements.txt"

if [[ "$INSTALL_FLASH_ATTN" == "1" ]]; then
  set +e
  "$VENV_DIR/bin/pip" install psutil ninja
  "$VENV_DIR/bin/pip" install --no-build-isolation flash-attn
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    if [[ "$FLASH_ATTN_STRICT" == "1" ]]; then
      exit "$rc"
    fi
    printf 'flash-attn install failed; continuing without fa3\n' >&2
  fi
fi

if [[ "$DOWNLOAD_DATA" == "1" ]]; then
  download_cmd=(
    "$VENV_DIR/bin/python"
    "$REPO_DIR/data/cached_challenge_fineweb.py"
    --variant
    "$DATA_VARIANT"
  )
  if [[ -n "$TRAIN_SHARDS" ]]; then
    download_cmd+=(--train-shards "$TRAIN_SHARDS")
  fi
  "${download_cmd[@]}"
fi

printf 'Setup complete: %s\n' "$REPO_DIR"
