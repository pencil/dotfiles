# Global Guidelines

## Starting a task: investigate, then ask

Default to asking rather than assuming. I'd rather answer several questions up
front than have you guess wrong.

Before non-trivial work:

1. Read relevant files first; don't ask what you can find out yourself.
2. Then ask about anything ambiguous. Sweep through intent, scope, constraints,
   and how we'll know it's done. Surface every ambiguity you notice, not just
   the biggest one.
3. Restate the task in your own words so I can catch misinterpretations.

When I give new instructions to adjust an outcome, repeat this
investigate-then-ask behavior.

If you have no way to reach me, such as a scheduled task, a non-interactive
run, or a subagent that can't ask, don't block on questions. Make the safest
reasonable assumption, flag it prominently in your output, and continue.

When a fact is version- or time-sensitive, verify it from code or with a web
search instead of assuming. Stable fundamentals don't need a search.

## Presenting options

When you need me to pick between concrete choices, prefer Codex's structured
question UI when it is available.

When options don't fit that UI, present them as a labeled list:

- Top-level options get numbers: `1.`, `2.`, `3.`
- Sub-variants under an option get letters: `1a.`, `1b.`
- Only nest when an option actually has variants.

## Code comments and docs

Write for a future reader who has the code but none of the context that
produced it.

Don't:

- Narrate the change or reference the conversation.
- Restate what the code already says.
- Leave debugging notes, hedges, or scaffolding behind.

Do:

- Comment the reason, constraint, tradeoff, invariant, or workaround.
- Prefer a clearer name or smaller function to a comment.
- Keep comments independent of line numbers and other details that drift.

Use the same rules for docstrings and Markdown. Describe the thing as it is,
not its history, unless the file is a changelog.

## Writing

- Avoid paired single tildes because GitHub renders them as strikethrough.
- Wrap bare `@xyz` names in backticks unless pinging that user is the goal.
- In runbooks, prefer clear callouts over dense text.

## Scripts

- All scripts must be bash/zsh-compatible. Avoid bash associative arrays and
  take care with word splitting and tmux flags such as `-t 0`.
- When cleaning worktrees, account for root-owned Docker artifacts.
