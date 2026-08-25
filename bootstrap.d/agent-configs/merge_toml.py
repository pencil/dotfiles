"""Deep-merge TOML documents using only the Python standard library."""

from __future__ import annotations

import copy
import datetime as dt
import json
import math
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


BARE_KEY = re.compile(r"^[A-Za-z0-9_-]+$")


def load_toml(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as config_file:
            document = tomllib.load(config_file)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise SystemExit(f"{path}: {error}") from error

    if not isinstance(document, dict):
        raise SystemExit(f"{path}: expected a TOML document")
    return document


def deep_merge(local: dict[str, Any], managed: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(local)
    for key, managed_value in managed.items():
        local_value = merged.get(key)
        if isinstance(local_value, dict) and isinstance(managed_value, dict):
            merged[key] = deep_merge(local_value, managed_value)
        else:
            merged[key] = copy.deepcopy(managed_value)
    return merged


def format_key(key: str) -> str:
    if BARE_KEY.fullmatch(key):
        return key
    return json.dumps(key, ensure_ascii=False)


def format_value(value: Any) -> str:
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if math.isnan(value):
            return "nan"
        if math.isinf(value):
            return "-inf" if value < 0 else "inf"
        return repr(value)
    if isinstance(value, dt.datetime):
        return value.isoformat(sep="T")
    if isinstance(value, (dt.date, dt.time)):
        return value.isoformat()
    if isinstance(value, list):
        return "[" + ", ".join(format_value(item) for item in value) + "]"
    if isinstance(value, dict):
        entries = (
            f"{format_key(key)} = {format_value(item)}" for key, item in value.items()
        )
        return "{ " + ", ".join(entries) + " }"
    raise TypeError(f"unsupported TOML value: {type(value).__name__}")


def emit_table(path: tuple[str, ...], table: dict[str, Any], lines: list[str]) -> None:
    assignments = [
        (key, value) for key, value in table.items() if not isinstance(value, dict)
    ]
    subtables = [(key, value) for key, value in table.items() if isinstance(value, dict)]

    if path and (assignments or not subtables):
        if lines and lines[-1]:
            lines.append("")
        lines.append("[" + ".".join(format_key(part) for part in path) + "]")

    lines.extend(f"{format_key(key)} = {format_value(value)}" for key, value in assignments)

    for key, subtable in subtables:
        emit_table((*path, key), subtable, lines)


def dump_toml(document: dict[str, Any]) -> str:
    lines: list[str] = []
    emit_table((), document, lines)
    return "\n".join(lines) + "\n"


def main() -> None:
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        load_toml(Path(sys.argv[2]))
        return
    if len(sys.argv) != 4:
        raise SystemExit("usage: merge_toml.py LOCAL MANAGED OUTPUT")

    local_path, managed_path, output_path = map(Path, sys.argv[1:])
    merged = deep_merge(load_toml(local_path), load_toml(managed_path))
    try:
        output_path.write_text(dump_toml(merged), encoding="utf-8")
    except (OSError, TypeError) as error:
        raise SystemExit(f"{output_path}: {error}") from error


if __name__ == "__main__":
    main()
