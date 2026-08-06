# Global Guidelines

## Starting a task: investigate, then ask

Default to asking rather than assuming. I'd rather answer several questions up front than have you guess wrong.

Before non-trivial work:

1. Read relevant files first — don't ask what you can find out yourself.
2. Then ask about anything ambiguous. Sweep through intent, scope, constraints, and how we'll know it's done. Surface every ambiguity you notice, not just the biggest one.
3. Restate the task in your own words so I can catch misinterpretations.

When I give new instructions to adjust an outcome, repeat this investigate-then-ask behavior.

If you have no way to reach me — a scheduled task, a non-interactive run, or you are a subagent that can't ask — don't block on questions: make the safest reasonable assumption, flag it prominently in your output, and continue.

When a fact is version- or time-sensitive — library APIs, tool versions, documentation, pricing, anything that may have drifted since your training data — verify it from code (1st as well as 3rd party, if available) or with a web search instead of assuming. Stable fundamentals (language syntax, well-established algorithms) don't need a search.

## Presenting options

When you need me to pick between concrete choices to proceed, prefer AskUserQuestion — it's easier to answer than prose.

When options don't fit that tool (more than 4, long or open-ended directions, code blocks, or a recommendation needs extra context rather than just a pick), present them as a labeled list so I can reference them in my reply:

- Top-level options get numbers: `1.`, `2.`, `3.`
- Sub-variants under an option get letters: `1a.`, `1b.`
- Only nest when an option actually has variants; otherwise stay flat.

## Code comments & docs

Write for a future reader who has the code but none of the context that produced it — not the conversation, the diff, the previous version, or the task. Litmus test: would the comment still read correctly to someone six months from now who never saw the change that introduced it? If it only makes sense as a footnote to this session, cut it or rewrite it.

Don't:

- **Narrate the change.**
  No `// switched to a set for faster lookup`, `// now also handles the empty case`, `// removed the old retry path`. Words like *now, new, old, previously, changed, instead* are a flag to re-check, not banned — strip them when they describe a before-state of the code the reader can't see, but keep them for runtime or domain state (`// the cache is now stale until the next write`).
- **Reference the conversation or task.**
  No `// per your request`, `// the edge case you mentioned`, `// as discussed`. The reader wasn't there.
- **Restate what the code already says.**
  `// increment the counter` above `count++` is noise. If the code is clear, leave it alone.
- **Leave scaffolding behind.**
  Strip debugging notes, hedges, and apologetic asides before you finish.

Do:

- **Comment the why, not the what.**
  The code shows what happens; a good comment explains what isn't visible from reading it — a constraint, a non-obvious tradeoff, an invariant that must hold, or a workaround for a specific bug (link the issue).
- **Prefer a clearer name to a comment.**
  A better-named variable or a smaller function often removes the need for the comment entirely.
- **Keep it durable.**
  Don't pin a comment to things that drift — line numbers, sibling function names, or literal values that aren't enforced right there. They rot silently when the code moves.

Same rules for docstrings and Markdown docs: describe the thing as it is, not its history ("Updated to support…") — unless the file is literally a changelog.

## Writing (PR descriptions, Notion docs)

- Avoid paired single tildes (`~x~`) — GitHub renders them as strikethrough. Use fenced code blocks or backticks for tokens instead.
- Avoid typing bare `@xyz` — GitHub pings that user. Wrap it in backticks unless pinging is the goal.
- In runbooks, prefer color-coded callout/highlight boxes over dense text.

## Scripts

- ALL scripts must be bash/zsh-compatible: avoid bash associative arrays, and be careful with word-splitting and tmux flags like `-t 0`.
- When cleaning worktrees, handle root-owned Docker artifacts (may need `sudo`).

## Watching a long-running process

- **`pgrep -f` matches the shell running it.** A wrapper that greps for a command string contains that string in its own `/proc/<pid>/cmdline`, so `pgrep -f "manage.py import"` matches itself — an `until`/`while pgrep -f ...` loop (in a `Monitor` command or a background Bash poll) then never exits, and a one-shot check reports a finished process as still running. Bracket a character in the pattern (`[m]anage.py import`) so the literal never matches itself, or match the pid directly (`kill -0 $pid`). Same trap with `ps aux | grep foo`.
- **Wait on the pid, not on a name.** If I launched the process, capture `$!` and poll `kill -0 "$pid"` (or `wait "$pid"`) — no pattern-matching surface, so it cannot self-match. This is the default whenever the pid is available.
- **Don't infer completion from process state.** Liveness says something is running, not that the work succeeded. Assert on the artifact — a log line, a row count, an output file — and use the process check only as a supporting signal.
- **Unbuffer long Python runs.** Python buffers stdout when it isn't a tty, so a `manage.py`-style job redirected to a file can show an empty or stale log while working fine. Use `python -u` or `PYTHONUNBUFFERED=1` so the log is a usable progress signal.
