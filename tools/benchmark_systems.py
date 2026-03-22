#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TRAIN_SCRIPT = ROOT / "train_gpt.py"
RESULTS_DIR = ROOT / "logs" / "benchmark_results"
TORCHRUN_BIN = os.environ.get("TORCHRUN_BIN", "torchrun")

TRAIN_STEP_RE = re.compile(
    r"step:(?P<step>\d+)/(?P<iterations>\d+) train_loss:(?P<loss>[0-9.]+) "
    r"train_time:(?P<train_time_ms>\d+)ms step_avg:(?P<step_avg_ms>[0-9.]+)ms"
)
ROUNDTRIP_RE = re.compile(
    r"final_int8_zlib_roundtrip_exact val_loss:(?P<val_loss>[0-9.]+) val_bpb:(?P<val_bpb>[0-9.]+)"
)
PEAK_MEMORY_RE = re.compile(
    r"peak memory allocated: (?P<allocated_mib>\d+) MiB reserved: (?P<reserved_mib>\d+) MiB"
)


@dataclass(frozen=True)
class Variant:
    name: str
    description: str
    env: dict[str, str]


VARIANTS = {
    "baseline": Variant(
        "baseline",
        "Original baseline transfer path",
        {"FUSE_BATCH_TRANSFER": "0"},
    ),
    "fused_batch_transfer": Variant(
        "fused_batch_transfer",
        "Transfer one shared token span to GPU before slicing x/y",
        {"FUSE_BATCH_TRANSFER": "1"},
    ),
    "fa3": Variant(
        "fa3",
        "Use flash-attn backend instead of PyTorch SDPA",
        {"ATTENTION_IMPL": "fa3", "FUSE_BATCH_TRANSFER": "0"},
    ),
    "fa3_fused_batch_transfer": Variant(
        "fa3_fused_batch_transfer",
        "Use flash-attn with fused batch transfer",
        {"ATTENTION_IMPL": "fa3", "FUSE_BATCH_TRANSFER": "1"},
    ),
}


def parse_env_overrides(items: list[str]) -> dict[str, str]:
    overrides: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise ValueError(f"Expected KEY=VALUE, got {item}")
        key, value = item.split("=", 1)
        overrides[key] = value
    return overrides


def parse_log(log_path: Path, train_batch_tokens: int) -> dict[str, float | int | None]:
    train_steps: list[dict[str, float | int]] = []
    val_bpb: float | None = None
    val_loss: float | None = None
    allocated_mib: int | None = None
    reserved_mib: int | None = None

    with log_path.open("r", encoding="utf-8") as f:
        for line in f:
            train_match = TRAIN_STEP_RE.search(line)
            if train_match is not None:
                train_steps.append(
                    {
                        "step": int(train_match.group("step")),
                        "iterations": int(train_match.group("iterations")),
                        "train_time_ms": int(train_match.group("train_time_ms")),
                        "step_avg_ms": float(train_match.group("step_avg_ms")),
                    }
                )
                continue

            roundtrip_match = ROUNDTRIP_RE.search(line)
            if roundtrip_match is not None:
                val_loss = float(roundtrip_match.group("val_loss"))
                val_bpb = float(roundtrip_match.group("val_bpb"))
                continue

            peak_memory_match = PEAK_MEMORY_RE.search(line)
            if peak_memory_match is not None:
                allocated_mib = int(peak_memory_match.group("allocated_mib"))
                reserved_mib = int(peak_memory_match.group("reserved_mib"))

    if not train_steps:
        raise ValueError(f"No training-step logs found in {log_path}")

    tail_step_ms = train_steps[-1]["step_avg_ms"]
    if len(train_steps) >= 2:
        step_delta = train_steps[-1]["step"] - train_steps[-2]["step"]
        time_delta = train_steps[-1]["train_time_ms"] - train_steps[-2]["train_time_ms"]
        if step_delta > 0:
            tail_step_ms = time_delta / step_delta

    tokens_per_second = train_batch_tokens / (tail_step_ms / 1000.0)
    return {
        "final_step": int(train_steps[-1]["step"]),
        "final_train_time_ms": int(train_steps[-1]["train_time_ms"]),
        "final_step_avg_ms": float(train_steps[-1]["step_avg_ms"]),
        "tail_step_ms": float(tail_step_ms),
        "tokens_per_second": float(tokens_per_second),
        "roundtrip_val_loss": val_loss,
        "roundtrip_val_bpb": val_bpb,
        "peak_allocated_mib": allocated_mib,
        "peak_reserved_mib": reserved_mib,
    }


def run_variant(
    variant: Variant,
    base_env: dict[str, str],
    common_overrides: dict[str, str],
) -> dict[str, object]:
    run_id = f"{base_env['RUN_ID_PREFIX']}_{variant.name}"
    log_path = ROOT / "logs" / f"{run_id}.txt"
    stdout_path = RESULTS_DIR / f"{run_id}.stdout.txt"
    env = os.environ.copy()
    env.update({k: v for k, v in base_env.items() if k != "RUN_ID_PREFIX"})
    env.update(common_overrides)
    env.update(variant.env)
    env["RUN_ID"] = run_id

    cmd = [
        TORCHRUN_BIN,
        "--standalone",
        "--nproc_per_node=1",
        str(TRAIN_SCRIPT),
    ]

    print(f"\n=== {variant.name} ===")
    print(variant.description)
    print("env:", json.dumps(variant.env, sort_keys=True))
    sys.stdout.flush()

    t0 = time.perf_counter()
    proc = subprocess.Popen(
        cmd,
        cwd=ROOT,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    captured: list[str] = []
    assert proc.stdout is not None
    for line in proc.stdout:
        captured.append(line)
        print(f"[{variant.name}] {line}", end="")
    return_code = proc.wait()
    wallclock_seconds = time.perf_counter() - t0

    stdout_path.write_text("".join(captured), encoding="utf-8")

    result: dict[str, object] = {
        "name": variant.name,
        "description": variant.description,
        "env": variant.env,
        "run_id": run_id,
        "return_code": return_code,
        "wallclock_seconds": round(wallclock_seconds, 3),
        "log_path": str(log_path.relative_to(ROOT)) if log_path.exists() else None,
        "stdout_path": str(stdout_path.relative_to(ROOT)),
    }

    if return_code != 0:
        result["status"] = "failed"
        return result

    if not log_path.exists():
        result["status"] = "missing_log"
        return result

    result["status"] = "ok"
    result.update(parse_log(log_path, int(env["TRAIN_BATCH_TOKENS"])))
    return result


def print_summary(results: list[dict[str, object]]) -> None:
    baseline = next(
        (result for result in results if result.get("name") == "baseline"), None
    )
    baseline_tail_ms = baseline.get("tail_step_ms") if baseline else None
    baseline_tps = baseline.get("tokens_per_second") if baseline else None

    header = (
        f"{'variant':<24} {'status':<10} {'tail_ms':>10} {'tok/s':>12} "
        f"{'delta_ms':>10} {'delta_tok/s':>12} {'wall_s':>10}"
    )
    print("\n" + header)
    print("-" * len(header))
    for result in results:
        tail_ms = result.get("tail_step_ms")
        tps = result.get("tokens_per_second")
        delta_ms = None
        delta_tps = None
        if isinstance(baseline_tail_ms, float) and isinstance(tail_ms, float):
            delta_ms = 100.0 * (baseline_tail_ms - tail_ms) / baseline_tail_ms
        if isinstance(baseline_tps, float) and isinstance(tps, float):
            delta_tps = 100.0 * (tps - baseline_tps) / baseline_tps

        print(
            f"{result['name']:<24} {result['status']:<10} "
            f"{(f'{tail_ms:.2f}' if isinstance(tail_ms, float) else 'n/a'):>10} "
            f"{(f'{tps:,.0f}' if isinstance(tps, float) else 'n/a'):>12} "
            f"{(f'{delta_ms:+.2f}%' if isinstance(delta_ms, float) else 'n/a'):>10} "
            f"{(f'{delta_tps:+.2f}%' if isinstance(delta_tps, float) else 'n/a'):>12} "
            f"{result['wallclock_seconds']:>10.3f}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Benchmark systems-only baseline variants on 1xH100"
    )
    parser.add_argument(
        "--variants",
        default="baseline,fused_batch_transfer,fa3,fa3_fused_batch_transfer",
        help="Comma-separated variant names",
    )
    parser.add_argument("--data-path", default="./data/datasets/fineweb10B_sp1024")
    parser.add_argument(
        "--tokenizer-path", default="./data/tokenizers/fineweb_1024_bpe.model"
    )
    parser.add_argument("--vocab-size", type=int, default=1024)
    parser.add_argument("--iterations", type=int, default=200)
    parser.add_argument("--warmup-steps", type=int, default=20)
    parser.add_argument("--train-batch-tokens", type=int, default=524288)
    parser.add_argument("--train-seq-len", type=int, default=1024)
    parser.add_argument("--train-log-every", type=int, default=50)
    parser.add_argument("--seed", type=int, default=1337)
    parser.add_argument("--run-prefix", default="bench_1xh100")
    parser.add_argument(
        "--env",
        action="append",
        default=[],
        help="Extra env override in KEY=VALUE form; may be repeated",
    )
    args = parser.parse_args()

    variant_names = [name.strip() for name in args.variants.split(",") if name.strip()]
    missing = [name for name in variant_names if name not in VARIANTS]
    if missing:
        raise ValueError(f"Unknown variants: {', '.join(missing)}")

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    base_env = {
        "RUN_ID_PREFIX": args.run_prefix,
        "DATA_PATH": args.data_path,
        "TOKENIZER_PATH": args.tokenizer_path,
        "VOCAB_SIZE": str(args.vocab_size),
        "ITERATIONS": str(args.iterations),
        "WARMUP_STEPS": str(args.warmup_steps),
        "TRAIN_BATCH_TOKENS": str(args.train_batch_tokens),
        "TRAIN_SEQ_LEN": str(args.train_seq_len),
        "TRAIN_LOG_EVERY": str(args.train_log_every),
        "VAL_LOSS_EVERY": "0",
        "MAX_WALLCLOCK_SECONDS": "0",
        "SKIP_FINAL_EVAL": "1",
        "SEED": str(args.seed),
    }
    common_overrides = parse_env_overrides(args.env)

    results: list[dict[str, object]] = []
    for name in variant_names:
        results.append(run_variant(VARIANTS[name], base_env, common_overrides))

    summary_path = RESULTS_DIR / f"{args.run_prefix}.json"
    summary_path.write_text(
        json.dumps(results, indent=2, sort_keys=True), encoding="utf-8"
    )
    print_summary(results)
    print(f"\nSaved summary to {summary_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
