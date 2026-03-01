# ai-dev-context

A two-tier AI context and memory system for Claude Code and other AI coding assistants.

Solves the two most painful problems with AI-assisted development:

1. **Context loss between sessions** — every new session starts cold, re-explaining the same project background
2. **Multi-tool drift** — Cursor, Windsurf, Cline, GitHub Copilot, and Codex each need their own config format; keeping them in sync is manual and error-prone

Developed on **macOS**. Both scripts are POSIX-compatible bash with no platform-specific dependencies, so Linux (Ubuntu/Debian) should work — but hasn't been tested yet.

---

## How it works

```
  Tier 1: ~/.config/ai/context.md          ─┐
  Tier 2: ~/.config/ai/projects/<repo>.md  ─┴── ai-config-sync.sh ──► .claude/CLAUDE.md     → Claude Code
               │                                                    ──► .cursorrules          → Cursor
               │                                                    ──► .windsurfrules        → Windsurf
               │                                                    ──► .clinerules           → Cline
               │                                                    ──► copilot-instructions  → Copilot
               │                                                    ──► AGENTS.md             → Codex
               │
               └── ai-memory-link.sh ──► ~/.claude/projects/<encoded>/memory/MEMORY.md
                                                    (symlink → Tier 2)
                                                          │
                                                          └─ auto-injected by Claude Code at session start
```

The scripts live in your PATH (e.g. `~/.local/bin/`) and are run once per project.

---

## Quickstart

```bash
# 1. Install your global context
mkdir -p ~/.config/ai
cp templates/context.md ~/.config/ai/context.md
# Edit it — fill in {{MACHINE_SPECS}}, {{AI_TOOLS_LIST}}, adjust prefs

# 2. Install the scripts
cp scripts/ai-config-sync.sh scripts/ai-memory-link.sh ~/.local/bin/
chmod +x ~/.local/bin/ai-config-sync.sh ~/.local/bin/ai-memory-link.sh

# 3. Set up a project
cd /path/to/your-project
ai-memory-link.sh .          # creates ~/.config/ai/projects/your-project.md + symlink
ai-config-sync.sh --all .    # writes .claude/CLAUDE.md, .cursorrules, .windsurfrules, etc.
```

That's it. Open the project in any AI tool — it reads its config and has full context.

---

## Tier 1 — Global context (`~/.config/ai/context.md`)

This file is the source of truth for everything that applies to every project:

- Machine specs and OS details
- AI tools installed
- Runtime management (mise, nvm, etc.)
- Language and linting preferences
- Architecture principles
- Design axiom and quality rules
- Commit message and PR style

See [`templates/context.md`](templates/context.md) for the template and [`examples/context.md`](examples/context.md) for a filled-in example (macOS-specific — Linux users substitute their own specs for `{{MACHINE_SPECS}}`).

---

## Tier 2 — Project memory (`~/.config/ai/projects/<repo-name>.md`)

This file tracks the evolving state of a specific project:

- Implementation status (what's built, what works, what's pending)
- Key technical decisions and why they were made
- Bugs fixed and the patterns that solved them
- Workflow commands for common tasks

The file lives outside any repo (`~/.config/ai/projects/`) so it:
- Persists across worktrees, branches, and forks
- Is never accidentally committed
- Can be backed up or version-controlled independently

`ai-memory-link.sh` creates a symlink at the path Claude Code expects (`~/.claude/projects/<encoded-path>/memory/MEMORY.md`), so Claude auto-injects the memory at session start without any extra configuration.

See [`templates/MEMORY.md`](templates/MEMORY.md) for the skeleton and [`examples/MEMORY.md`](examples/MEMORY.md) for a filled-in example.

---

## ai-config-sync.sh — multi-tool config generation

`ai-config-sync.sh` reads your Tier 1 global context and Tier 2 project memory, then writes tool-specific config files. Each tool has its own format; the script handles the differences.

```bash
ai-config-sync.sh --all /path/to/project

# Or selectively:
ai-config-sync.sh --cursor --windsurf .
```

| Flag | Output file |
|------|-------------|
| (default) | `.claude/CLAUDE.md` |
| `--cursor` | `.cursorrules` |
| `--windsurf` | `.windsurfrules` |
| `--cline` | `.clinerules` |
| `--copilot` | `.github/copilot-instructions.md` |
| `--codex` | `AGENTS.md` |
| `--all` | all of the above |

Generated files are added to `.gitignore` automatically. See [`docs/CROSS_TOOL_SYNC.md`](docs/CROSS_TOOL_SYNC.md) for details on why generation is better than symlinks.

---

## Complementary tools

These tools solve adjacent problems and work well alongside this system:

| Tool | What it does | Relationship |
|------|-------------|--------------|
| [claude-mem](https://github.com/sirmews/claude-mem) | Captures sessions, compresses with AI, SQLite+Chroma for vector search | Memory capture, no multi-tool sync |
| [claude-diary](https://github.com/rbigeard/claude-diary) | Auto-updates CLAUDE.md from session activity | Closer to auto-MEMORY.md; Claude-only |
| [memory-mcp](https://github.com/modelcontextprotocol/servers) | MCP server + git versioning per session | Complementary for MCP workflows |
| AGENTS.md pattern | Single master file + symlinks | Simpler; doesn't handle per-tool format differences |
| [ClaudeMDEditor](https://marketplace.visualstudio.com/items?itemName=ClaudeMDEditor) | Visual UI to manage AI config files | GUI wrapper, no automation |

---

## Known limitations

- Memory is auto-injected at session start ✅
- Memory is **not** auto-saved when you close the window — the `SessionEnd` hook does not reliably fire; VS Code terminates the extension host before it completes
- The only reliable way to save memory is to explicitly ask Claude to save before you close (e.g. "save memory and wrap up")

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for open problems worth solving.
