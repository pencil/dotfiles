#!/usr/bin/env bash
# Claude Code status line — minimal, sleek
# Shows: context bar · model · effort

# Ensure UTF-8 so Unicode glyphs render in any locale (C.UTF-8 is
# available on virtually every modern Linux/macOS system).
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *.[Uu][Tt][Ff][-]8*|*.[Uu][Tt][Ff]8*) ;;
  *) export LC_CTYPE=C.UTF-8 ;;
esac

input=$(cat)

# ── Context window progress bar ──────────────────────────────────────────────
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  bar_width=10

  # Half-character precision
  complete_halves=$(( used_int * bar_width * 2 / 100 ))
  bar_count=$(( complete_halves / 2 ))
  half_bar=$(( complete_halves % 2 ))

  # Color: green -> yellow -> red as context fills up
  if   [ "$used_int" -lt 50 ]; then color="\033[32m"   # green
  elif [ "$used_int" -lt 80 ]; then color="\033[33m"   # yellow
  else                               color="\033[31m"   # red
  fi
  dim="\033[2;90m"
  rst="\033[0m"

  # repeat '━' N times (tr mangles multi-byte chars)
  rep() { local s=''; local i; for ((i=0; i<$1; i++)); do s+='━'; done; printf '%s' "$s"; }

  bar=""
  # Filled portion
  if [ "$bar_count" -gt 0 ]; then
    filled=$(rep "$bar_count")
    bar="${bar}$(printf "${color}${filled}${rst}")"
  fi
  # Half bar cap
  if [ "$half_bar" -eq 1 ]; then
    bar="${bar}$(printf "${color}╸${rst}")"
  fi
  # Remaining
  remaining=$(( bar_width - bar_count - half_bar ))
  if [ "$remaining" -gt 0 ]; then
    if [ "$half_bar" -eq 0 ] && [ "$bar_count" -gt 0 ]; then
      empty=$(rep $(( remaining - 1 )))
      bar="${bar}$(printf "${dim}╺${empty}${rst}")"
    else
      empty=$(rep "$remaining")
      bar="${bar}$(printf "${dim}${empty}${rst}")"
    fi
  fi

  ctx_part=$(printf "%s${color}%3d%%${rst}" "$bar" "$used_int")
else
  ctx_part=$(printf "\033[2;90m━━━━━━━━━━  –%%\033[0m")
fi

# ── Model ────────────────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // ""')
model=$(echo "$model" | sed 's/ (.*//')

# ── Effort ───────────────────────────────────────────────────────────────────
effort=$(echo "$input" | jq -r '.effort.level // ""')
if [ -z "$effort" ]; then
  effort=$(jq -r '.effortLevel // ""' "$HOME/.claude/settings.json" 2>/dev/null)
fi

effort_color="\033[35m"  # magenta for everything except max
if   [ "$effort" = "max" ];    then effort_glyphs="◆◆◆◆🔥"; effort_color="\033[91m"  # bright red
elif [ "$effort" = "xhigh" ];  then effort_glyphs="◆◆◆◆"
elif [ "$effort" = "high" ];   then effort_glyphs="◆◆◆◇"
elif [ "$effort" = "medium" ]; then effort_glyphs="◆◆◇◇"
elif [ "$effort" = "low" ];    then effort_glyphs="◆◇◇◇"
else                                effort_glyphs="    "
fi
effort_str=$(printf "${effort_color}%s\033[0m" "$effort_glyphs")

# ── tmux window rename ───────────────────────────────────────────────────────
# Sync the Claude session name (set via /rename) to the tmux window name.
# Disables tmux's automatic rename for this window as a side effect.
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  session_name=$(echo "$input" | jq -r '.session_name // empty')
  if [ -n "$session_name" ]; then
    tmux rename-window -t "$TMUX_PANE" "$session_name" 2>/dev/null || true
  fi
fi

# ── Compose ──────────────────────────────────────────────────────────────────
sep=$(printf "\033[2m·\033[0m")

printf "%s  %s  %s  %s  %s\n" \
  "$ctx_part" \
  "$sep" \
  "$(printf '\033[37m%s\033[0m' "$model")" \
  "$sep" \
  "$effort_str"
