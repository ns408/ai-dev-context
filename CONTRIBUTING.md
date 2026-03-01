# Contributing

This project is in early, working state. Contributions that improve clarity, fix bugs in the scripts, or tackle the open problems below are welcome.

---

## Open problems worth solving

### 1. Memory review UX before commit

**The gap:** Claude Code's auto-memory writes MEMORY.md silently during a session. There's no moment where you review what was written before it becomes permanent. You might end up persisting wrong conclusions, misattributed bugs, or stale state.

**The idea:** A `PostToolUse` hook that fires whenever MEMORY.md is written. The hook would show a diff of changes and prompt: approve, edit, or discard.

```json
// .claude/settings.json
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
1. Check if the written file is `MEMORY.md`
2. Show `git diff` of the change
3. Prompt: approve / edit / discard
4. On discard: `git checkout -- MEMORY.md`

This is genuinely unaddressed by any existing tool (as of early 2026). A clean implementation here would be a meaningful contribution.

---

### 2. Cross-project lessons extractor

**The gap:** Patterns and fixes discovered in one project often apply elsewhere. Right now they live in per-project MEMORY.md files and are never surfaced elsewhere.

**The idea:** A script that scans all `~/.config/ai/projects/*.md` files, extracts `## Bugs Fixed` and `## Key Technical Decisions` sections, and writes a deduplicated `~/.config/ai/lessons.md`. That file could then be injected into `~/.config/ai/context.md` or referenced from project CLAUDE.md files.

Possible implementation:
- Parse MEMORY.md files with a simple markdown section extractor
- Deduplicate by semantic similarity (embeddings) or keyword clustering
- Output as a single lessons file, optionally appended to global context

---

### 3. Hook-based memory save: known gap on session close

**The gap:** The natural approach to auto-saving memory is two hooks working together: a `Stop` hook that fires after every response (triggered by a phrase you say when you want to save), and a `SessionEnd` hook as a mechanical fallback that parses the session transcript and writes whatever it can. Belt and suspenders.

The problem: **the SessionEnd hook does not reliably fire on any quit** — normal close or force-quit. VS Code terminates the extension host before the hook completes. The `Stop` hook is the only gate that actually works; `SessionEnd` is unreliable in practice.

This means:
- If you explicitly ask Claude to save memory before closing, it will be saved ✅
- If you just close the window, it probably won't be ❌

**The idea:** A reliable fallback that doesn't depend on the extension host staying alive — for example, periodic auto-save triggered from within the session (not on exit), or a pre-close save prompt surfaced by the IDE.

---

## How to submit

Open a pull request with a clear description of what problem it solves and how to test it. Small, focused changes are preferred over large rewrites.
