# Contributing

This project is in active development. Contributions that improve clarity, fix bugs in the scripts, or tackle the open problems below are welcome.

---

## Open problems worth solving

### 1. Auto-memory review before propagation

**The gap:** Claude Code auto-memory (v2.1.59+) writes to `~/.claude/projects/<encoded>/memory/MEMORY.md` silently during a session. There is no moment to review what was captured before it gets picked up in the next session. Wrong conclusions, misattributed bugs, or stale state can persist.

**The idea:** A `PostToolUse` hook that fires when Claude Code writes to a MEMORY.md file. The hook compares the new content against existing entries and either shows a diff for approval or blocks duplicate/contradictory entries automatically.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "scripts/review-memory-write.sh"
      }]
    }]
  }
}
```

The hook script would:
1. Check if the written file is a MEMORY.md in `~/.claude/projects/`
2. Compare new content against existing entries (string match or embeddings)
3. Exit with code 2 to block if a duplicate or contradiction is detected, with the reason sent via stderr back to Claude
4. Otherwise approve silently (exit 0)

Exit code 2 blocks the write before it lands, and stderr content is fed back to Claude as context to correct the entry. See [docs/HOOKS.md](docs/HOOKS.md) for the hook mechanics.

---

### 2. Cross-project lessons extractor

**The gap:** Patterns and fixes discovered in one project often apply elsewhere. Right now they are scattered across per-project memory files and are never surfaced globally.

**Partial solution:** Synthesising lessons manually into a `TEMP/lessons.md` file per project works well for deep research (pull from multiple sources, deduplicate, distil). The remaining gap is automation: a script that scans all project notes and extracts reusable patterns without manual effort.

**The idea:** A script that scans committed `project.md` files (or Claude Code auto-memory files), extracts `## Key Technical Decisions` sections, and writes a deduplicated `~/.config/ai/lessons.md`. That file could then be referenced from `~/.config/ai/context.md`.

Possible implementation:
- Parse project.md files with a simple markdown section extractor
- Deduplicate by semantic similarity (embeddings) or keyword clustering
- Output as a flat lessons file, optionally appended to global context

---

### 3. Kiro steering generation

**The gap:** `ai-config-sync.sh` generates configs for Claude Code, Cursor, Windsurf, Cline, Copilot, and Codex. It does not generate Kiro steering files.

Kiro uses a different shape: YAML-frontmatter markdown files in `.kiro/steering/`, one file per steering area (e.g. `identity.md`, `testing.md`). A flat injection of `context.md` into a single file would not map cleanly to Kiro's model.

**The idea:** A `--kiro` flag for `ai-config-sync.sh` that generates `.kiro/steering/identity.md` from the global context, splitting sections into separate steering files where appropriate.

This is lower priority until Kiro's adoption and steering file format stabilise.

---

## How to submit

Open a pull request with a clear description of what problem it solves and how to test it. Small, focused changes are preferred over large rewrites.
