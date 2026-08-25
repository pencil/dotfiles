#!/usr/bin/env bash
# Materialize user-level agent configs and apply the portable fragments from
# this repository. Keys absent from a fragment remain local; objects and TOML
# tables merge recursively, while fragment arrays and scalar values replace the
# corresponding local values.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/../.." && pwd -P)"
toml_merger="$script_dir/merge_toml.py"

claude_src="$script_dir/claude-settings.json"
claude_dst="$HOME/.claude/settings.json"
claude_legacy_src="$repo_root/claude/.claude/settings.json"
codex_src="$script_dir/codex-config.toml"
codex_dst="$HOME/.codex/config.toml"
codex_legacy_src="$repo_root/codex/.codex/config.toml"

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

resolve_link_target() {
  link=$1
  target=$(readlink "$link") || return 1

  case "$target" in
    /*) target_path=$target ;;
    *) target_path=$(dirname "$link")/$target ;;
  esac

  target_dir=$(dirname "$target_path")
  target_name=$(basename "$target_path")
  [[ -d "$target_dir" ]] || return 1
  printf '%s/%s\n' "$(cd "$target_dir" && pwd -P)" "$target_name"
}

materialize_config() {
  src=$1
  dst=$2
  name=$3
  legacy_src=$4
  dst_dir=$(dirname "$dst")
  backup="$dst.pre-dotfiles"

  mkdir -p "$dst_dir"

  if [[ -L "$dst" ]]; then
    copy_from=$dst
    resolved_target=$(resolve_link_target "$dst" || true)
    if [[ "$dst" -ef "$src" ]]; then
      :
    elif [[ "$resolved_target" == "$legacy_src" ]]; then
      # A checkout update can leave the former fragment symlink dangling.
      [[ -e "$dst" ]] || copy_from=$src
    else
      echo "Refusing to replace $dst: it does not link to a managed $name fragment" >&2
      exit 1
    fi

    if [[ ! -e "$backup" && ! -L "$backup" ]]; then
      cp -p "$copy_from" "$backup"
    fi

    tmp=$(mktemp "$dst_dir/.$(basename "$dst").materialize.XXXXXX")
    cp -p "$copy_from" "$tmp"
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

materialize_config "$claude_src" "$claude_dst" "Claude" "$claude_legacy_src"
materialize_config "$codex_src" "$codex_dst" "Codex" "$codex_legacy_src"
merge_json "$claude_src" "$claude_dst" "Claude"
merge_toml "$codex_src" "$codex_dst" "Codex"
