#!/usr/bin/env bash
# Materialize user-level agent configs and apply the portable fragments from
# this repository. Keys absent from a fragment remain local; objects and TOML
# tables merge recursively, while fragment arrays and scalar values replace the
# corresponding local values.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
toml_merger="$script_dir/merge_toml.py"

claude_src="$repo_root/claude/.claude/settings.json"
claude_dst="$HOME/.claude/settings.json"
codex_src="$repo_root/codex/.codex/config.toml"
codex_dst="$HOME/.codex/config.toml"

command -v jq >/dev/null || {
  echo "jq is required to merge Claude settings; run \`brew bundle\` first." >&2
  exit 1
}
if ! command -v python3 >/dev/null || ! python3 -c 'import tomllib' 2>/dev/null; then
  echo "Python 3.11 or later is required to merge Codex settings; run \`brew bundle\` first." >&2
  exit 1
fi

jq -e 'type == "object"' "$claude_src" >/dev/null
python3 "$toml_merger" --check "$codex_src"

materialize_config() {
  src=$1
  dst=$2
  name=$3
  dst_dir=$(dirname "$dst")
  backup="$dst.pre-dotfiles"

  mkdir -p "$dst_dir"

  if [[ -L "$dst" ]]; then
    if [[ ! "$dst" -ef "$src" ]]; then
      echo "Refusing to replace $dst: it does not link to $src" >&2
      exit 1
    fi

    if [[ ! -e "$backup" && ! -L "$backup" ]]; then
      cp -p "$dst" "$backup"
    fi

    tmp=$(mktemp "$dst_dir/.$(basename "$dst").materialize.XXXXXX")
    cp -p "$dst" "$tmp"
    mv -f "$tmp" "$dst"
    echo "Materialized $name config at $dst"
  elif [[ ! -e "$dst" ]]; then
    cp -p "$src" "$dst"
    echo "Created $name config at $dst"
  elif [[ ! -f "$dst" ]]; then
    echo "Refusing to replace $dst: expected a regular file" >&2
    exit 1
  fi
}

merge_json() {
  src=$1
  dst=$2
  name=$3
  dst_dir=$(dirname "$dst")
  tmp=$(mktemp "$dst_dir/.$(basename "$dst").merge.XXXXXX")

  cp -p "$dst" "$tmp"
  if ! jq -s '.[0] * .[1]' "$dst" "$src" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if cmp -s "$dst" "$tmp"; then
    rm -f "$tmp"
  else
    mv -f "$tmp" "$dst"
    echo "Merged portable $name settings into $dst"
  fi
}

merge_toml() {
  src=$1
  dst=$2
  name=$3
  dst_dir=$(dirname "$dst")
  tmp=$(mktemp "$dst_dir/.$(basename "$dst").merge.XXXXXX")

  cp -p "$dst" "$tmp"
  if ! python3 "$toml_merger" "$dst" "$src" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if cmp -s "$dst" "$tmp"; then
    rm -f "$tmp"
  else
    mv -f "$tmp" "$dst"
    echo "Merged portable $name settings into $dst"
  fi
}

materialize_config "$claude_src" "$claude_dst" "Claude"
materialize_config "$codex_src" "$codex_dst" "Codex"
merge_json "$claude_src" "$claude_dst" "Claude"
merge_toml "$codex_src" "$codex_dst" "Codex"
