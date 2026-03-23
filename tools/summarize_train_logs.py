#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


KV_RE = re.compile(r"(\w+):([^\s]+)")


def parse_log(path: Path) -> dict[str, object]:
    record: dict[str, object] = {"file": str(path)}
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for line in lines:
        if line.startswith("attention_impl:"):
            for key, value in KV_RE.findall(line):
                record[key] = value
        elif line.startswith("orthogonal_init:"):
            for key, value in KV_RE.findall(line):
                record[key] = value
        elif line.startswith("model_params:"):
            record["model_params"] = int(line.split(":", 1)[1])
        elif line.startswith("seed:"):
            record["seed"] = int(line.split(":", 1)[1])
        elif line.startswith("step:") and "val_loss:" in line:
            record["stop_line"] = line
            for key, value in KV_RE.findall(line):
                if key in {"step_avg", "val_loss", "val_bpb", "train_time"}:
                    record[key] = value
                elif key == "step":
                    record["stop_step"] = value
        elif "final_int8_zlib_roundtrip_exact" in line:
            record["final_line"] = line
            for key, value in KV_RE.findall(line):
                if key in {"val_loss", "val_bpb"}:
                    record[f"final_{key}"] = value
    return record


def expand_inputs(patterns: list[str]) -> list[Path]:
    paths: list[Path] = []
    seen: set[Path] = set()
    for pattern in patterns:
        matched = sorted(Path().glob(pattern))
        if matched:
            for path in matched:
                if path.is_file() and path not in seen:
                    paths.append(path)
                    seen.add(path)
        else:
            p = Path(pattern)
            if p.is_file() and p not in seen:
                paths.append(p)
                seen.add(p)
    return paths


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", help="log files or glob patterns")
    parser.add_argument("--output", help="optional JSON output path")
    args = parser.parse_args()

    records = [parse_log(path) for path in expand_inputs(args.paths)]
    text = json.dumps(records, indent=2, sort_keys=True)
    if args.output:
        Path(args.output).write_text(text + "\n", encoding="utf-8")
    else:
        print(text)


if __name__ == "__main__":
    main()
