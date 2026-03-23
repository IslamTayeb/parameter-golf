# 2026-03-22 - FA3 Hopper Install Guide

This is the shortest repeatable path we found for getting **working FA3 on an
H100/Hopper box** for `parameter-golf`.

## The important lesson

Do **not** rely on generic:

```bash
pip install flash-attn --no-build-isolation
```

for this workflow.

That route targets the general `flash-attn` package and was not the reliable way
to get the Hopper-specific path we needed. The working approach was to build the
**Hopper subpackage** from:

- `https://github.com/Dao-AILab/flash-attention`
- specifically `hopper/setup.py`

The installed module we care about is:

- `flash_attn_interface`

That is what our `ATTENTION_IMPL=fa3` path imports.

## Preconditions

This guide assumes:

- Linux
- H100 / Hopper GPU
- CUDA toolkit present, ideally `12.8`
- an existing project venv with `torch` already installed
- enough RAM / disk to compile a CUDA extension

On our Hyperbolic `1x H100 SXM5` box, the relevant pieces were:

- `torch 2.10.0+cu128`
- `CUDA_HOME=/usr/local/cuda-12.8`
- system `ninja-build`

## One-shot install script

We added a helper script:

- `tools/install_fa3_hopper.sh`

Typical usage on a fresh H100 Linux box:

```bash
VENV_DIR=$HOME/parameter-golf/.venv \
CUDA_HOME=/usr/local/cuda-12.8 \
tools/install_fa3_hopper.sh
```

What it does:

- installs `git`, `build-essential`, and `ninja-build` when `apt-get` is available
- clones `Dao-AILab/flash-attention` with submodules
- installs minimal Python deps into the target venv
- builds from `hopper/setup.py`
- runs an import check for `flash_attn_interface`

## Why the script uses an aggressive "lean H100" build

For `parameter-golf`, the default trainer only needs a narrow slice of FA3:

- Hopper / SM90 only
- BF16 path
- head dimension `64`
- no FP8
- no local attention
- no paged KV features

So the script sets several `FLASH_ATTENTION_DISABLE_*` env vars to avoid
compiling a bunch of kernels we do not need.

This materially reduces build pain.

The key assumptions behind the lean build are true for the default repo config:

- `MODEL_DIM=512`
- `NUM_HEADS=8`
- head dim = `64`
- BF16 training path

If we later change model shape or need other FA3 features, rerun with:

```bash
LEAN_H100_BUILD=0 tools/install_fa3_hopper.sh
```

## Manual commands that worked

If you want the exact manual flow instead of the helper script, this is the
working sequence:

```bash
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential ninja-build

git clone --recursive --depth 1 https://github.com/Dao-AILab/flash-attention.git ~/flash-attention

$HOME/parameter-golf/.venv/bin/pip install --upgrade pip setuptools wheel
$HOME/parameter-golf/.venv/bin/pip install einops packaging ninja

cd ~/flash-attention/hopper
rm -rf build dist flash_attn_3.egg-info

export CUDA_HOME=/usr/local/cuda-12.8
export PATH="$HOME/parameter-golf/.venv/bin:$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
export MAX_JOBS=4
export NVCC_THREADS=2

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

$HOME/parameter-golf/.venv/bin/python setup.py install
```

## Quick verification

First verify the package imports:

```bash
$HOME/parameter-golf/.venv/bin/python -c 'import flash_attn_interface; print(hasattr(flash_attn_interface, "flash_attn_func"))'
```

That should print `True`.

Then do a tiny trainer smoke test:

```bash
cd $HOME/parameter-golf
RUN_ID=fa3_smoke \
DATA_PATH=$HOME/parameter-golf/data/datasets/fineweb10B_sp1024 \
TOKENIZER_PATH=$HOME/parameter-golf/data/tokenizers/fineweb_1024_bpe.model \
VOCAB_SIZE=1024 \
TRAIN_BATCH_TOKENS=8192 \
ITERATIONS=2 \
MAX_WALLCLOCK_SECONDS=0 \
VAL_LOSS_EVERY=0 \
ATTENTION_IMPL=fa3 \
FUSE_BATCH_TRANSFER=1 \
$HOME/parameter-golf/.venv/bin/torchrun --standalone --nproc_per_node=1 train_gpt.py
```

The important line to see is:

- `attention_impl:fa3 fuse_batch_transfer:1`

## Common pitfalls

- `pip install flash-attn` is not the clean FA3/Hopper path we wanted here.
- If `torch` says it cannot find `ninja`, install system `ninja-build` and make
  sure `ninja` is on `PATH`.
- If `nvcc` is missing, point `CUDA_HOME` at the real toolkit root.
- If the build is taking forever, make sure it is not silently falling back to a
  broader kernel set than we need.
- If you remove the `FLASH_ATTENTION_DISABLE_*` filters, expect a much larger build.

## Strict future baseline setup

For a true baseline-vs-best-stack rerun, also clone upstream separately:

```bash
git clone --depth 1 https://github.com/openai/parameter-golf.git $HOME/parameter-golf-openai
```

The exact official naive baseline snapshot then lives at:

- `$HOME/parameter-golf-openai/records/track_10min_16mb/2026-03-17_NaiveBaseline/train_gpt.py`

That lets us compare:

- strict naive baseline from the frozen record snapshot
- against our current best stack with `ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1`

without mixing the two codepaths.
