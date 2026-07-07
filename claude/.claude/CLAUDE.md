# Global Guidelines

## Writing (PR descriptions, Notion docs)
- Avoid paired single tildes (`~x~`) — GitHub renders them as strikethrough. Use fenced code blocks or backticks for tokens instead.
- In runbooks, prefer color-coded callout/highlight boxes over dense text.

## Scripts
- ALL scripts must be bash/zsh-compatible: avoid bash associative arrays, and be careful with word-splitting and tmux flags like `-t 0`.
- When cleaning worktrees, handle root-owned Docker artifacts (may need `sudo`).
