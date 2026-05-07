# Claude Code Hooks

Hooks let you run shell commands automatically at key points in Claude Code's workflow. The critical difference from CLAUDE.md instructions: **hooks guarantee execution**. A CLAUDE.md instruction is advisory — Claude may or may not follow it. A hook runs every time, regardless.

---

## Configuration

Hooks live in `.claude/settings.json` (project-level) or `~/.claude/settings.json` (global):

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "your-script.sh"
      }]
    }]
  }
}
```

Key fields:

| Field | Notes |
|-------|-------|
| `PostToolUse` / `PreToolUse` | When to fire. Pre-tool hooks can block; post-tool hooks observe. |
| `matcher` | Pipe-separated tool names to match: `"Write\|Edit\|Bash"` |
| `command` | Shell command to run. Receives tool context via stdin as JSON. |

**Stdin JSON shape:**

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file",
    "content": "..."
  }
}
```

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0` | Allow. No feedback. |
| `2` | Block (PreToolUse only). Stderr content is sent back to Claude as context. |
| Other | Allow, but stderr content is sent to Claude as a warning. |

Stderr output on exit code 2 goes directly into Claude's context — use it to explain what's wrong so Claude can correct the action before retrying.

---

## Pattern 1 — TypeScript type checker

Run `tsc --no-emit` after every TypeScript file edit. Claude receives type errors in context and auto-fixes call sites before moving on.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'echo $CLAUDE_TOOL_INPUT | jq -r .tool_input.file_path | grep -qE \"\\.(ts|tsx)$\" && tsc --no-emit 2>&1 || true'"
      }]
    }]
  }
}
```

Or as a standalone script (`scripts/typecheck-hook.sh`):

```bash
#!/usr/bin/env bash
input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
[[ "$file" =~ \.(ts|tsx)$ ]] || exit 0
output="$(tsc --no-emit 2>&1)"
[[ -z "$output" ]] && exit 0
echo "$output" >&2
exit 0  # warn but don't block — let Claude fix then re-check
```

Adapt to any typed language. For untyped languages, run your test suite instead.

---

## Pattern 2 — Python linting

Run `black` and `flake8` after every Python file write. Exit 2 on violations so Claude sees the output and fixes before proceeding.

```bash
#!/usr/bin/env bash
# scripts/lint-python-hook.sh
input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
[[ "$file" =~ \.py$ ]] || exit 0

errors=""
black_out="$(black --check "$file" 2>&1)" || errors+="black: $black_out\n"
flake8_out="$(flake8 "$file" 2>&1)"       || errors+="flake8: $flake8_out\n"

[[ -z "$errors" ]] && exit 0
printf '%b' "$errors" >&2
exit 2
```

Wire it up:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "scripts/lint-python-hook.sh"}]
    }]
  }
}
```

---

## Pattern 3 — Duplicate code prevention

For directories where duplication is costly (query files, API clients, schema definitions), spawn a secondary Claude SDK instance to compare the new file against existing ones. If a near-duplicate is found, exit 2 with an explanation.

This is more expensive — a second Claude call per write — so apply it selectively.

```bash
#!/usr/bin/env bash
# scripts/dedup-hook.sh
input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
watched_dir="src/queries"

[[ "$file" == "$watched_dir"/* ]] || exit 0

# Spawn a secondary Claude instance to compare
result="$(claude --print "Does the new file below duplicate any existing file in $watched_dir/? If yes, name the existing file and explain the overlap. If no, reply UNIQUE.

New file: $file

$(cat "$file")")"

echo "$result" | grep -q "^UNIQUE" && exit 0

echo "Possible duplicate detected: $result" >&2
exit 2
```

Trade-offs: extra latency and token cost per write. Use only on paths where duplication is a real problem.

---

## When to use hooks vs CLAUDE.md

| Use case | Right tool |
|----------|-----------|
| "Always run the linter after editing Python" | Hook — must happen every time |
| "Prefer composition over inheritance" | CLAUDE.md — style guidance, judgment call |
| "Never write to the migrations directory" | Either — hook for hard enforcement, CLAUDE.md if advisory is enough |
| "Run tests after any change to src/" | Hook — deterministic, not optional |
