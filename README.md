# ai-dev-context

A tool for syncing your developer identity across AI coding assistants.

Your preferences, conventions, and project rules — written once, distributed to every tool you use.

Developed on **macOS**. The script is POSIX-compatible bash with no external dependencies, so Linux (Ubuntu/Debian) should work but hasn't been tested.

---

## The problem

Every AI coding tool (Claude Code, Cursor, Windsurf, Cline, Copilot, Codex) reads from a different config file in a different format. Keeping them in sync as your preferences evolve is manual and error-prone.

Most tools now capture session memories automatically. What they don't do is share your preferences across tools, or let you author them deliberately. This project maintains a single source of truth for your coding identity and generates the per-tool config each assistant expects.

---

## How it works

```
~/.config/ai/context.md         your global developer identity
.ai/project.md                  optional per-project rules (committed to repo)
        |
        v
  ai-config-sync.sh
        |
        +---> .claude/CLAUDE.md                (@ reference, stays live)     -> Claude Code
        +---> .cursorrules                     (inlined)                     -> Cursor
        +---> .windsurfrules                   (inlined)                     -> Windsurf
        +---> .clinerules                      (inlined)                     -> Cline
        +---> .github/copilot-instructions.md  (inlined)                     -> Copilot
        +---> AGENTS.md                        (inlined)                     -> Codex / others
```

The script lives in your PATH and is run once per project (or after updating your global context).

---

## Quickstart

```bash
# 1. Set up your global context
mkdir -p ~/.config/ai
cp templates/context.md ~/.config/ai/context.md
# Edit it: fill in {{MACHINE_SPECS}}, {{AI_TOOLS_LIST}}, adjust preferences

# 2. Install the script
cp scripts/ai-config-sync.sh ~/.local/bin/
chmod +x ~/.local/bin/ai-config-sync.sh

# 3. Sync a project
cd /path/to/your-project
ai-config-sync.sh --all .
```

Open the project in any AI tool. It reads its config and has your full context.

---

## Global context (`~/.config/ai/context.md`)

The source of truth for everything that applies to every project:

- Machine specs and OS details
- AI tools installed
- Runtime management (mise, nvm, etc.)
- Language and linting preferences
- Architecture principles
- Design axiom and quality rules
- Commit message and PR style

See [templates/context.md](templates/context.md) for the template and [examples/context.md](examples/context.md) for a filled-in example.

---

## ai-config-sync.sh

Reads your global context and writes tool-specific config files. Each tool has its own format; the script handles the differences.

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

Generated files are added to `.gitignore` automatically — they contain personal machine specs and preferences, so they should not be committed.

For Claude Code, the generated CLAUDE.md uses `@~/.config/ai/context.md` so context is loaded live at each session start. No re-sync needed when your global context changes. For all other tools, context is inlined at generation time, so re-run the script after significant updates.

See [docs/CROSS_TOOL_SYNC.md](docs/CROSS_TOOL_SYNC.md) for details.

---

## Optional: per-project rules (`.ai/project.md`)

For project-specific rules you want every tool to know — not just Claude Code:

```bash
mkdir -p .ai
cat > .ai/project.md << 'EOF'
- Use Bun, not npm or yarn
- Never edit files in db/migrations/ directly
- Auth logic lives in src/auth/ — check there before writing new auth code
EOF

ai-config-sync.sh --all .
```

This file is committed to the repo. It gets injected into every generated tool config alongside your global context. For Claude Code specifically, project-specific instructions are better placed in a committed `CLAUDE.md` — `.ai/project.md` earns its keep when you want the same rules in Cursor, Windsurf, or Cline too.

---

## Session memory

Claude Code (v2.1.59+), Windsurf Cascade, and GitHub Copilot all capture session memories automatically. You don't need to manage this manually.

`ai-memory-link.sh` in this repo was an earlier approach to centralising Claude Code's memory before auto-memory existed. It is now **deprecated** — kept for users on older Claude Code versions. See the script header for details.

---

## Complementary tools

| Tool | What it does | Relationship |
|------|-------------|--------------|
| [claude-mem](https://github.com/sirmews/claude-mem) | Captures sessions, compresses with AI, SQLite+Chroma vector search | Session capture only, no multi-tool sync |
| [claude-diary](https://github.com/rbigeard/claude-diary) | Auto-updates CLAUDE.md from session activity | Claude-only, no sync |
| [Knowledge Graph Memory](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) | Official Anthropic MCP server, entity/relation graph | Complementary for MCP-based memory workflows |
| [basic-memory](https://github.com/basicmachines-co/basic-memory) | Third-party MCP server, local-only, AGPL, hybrid full-text + vector search | Privacy-first alternative to cloud memory |
| [ClaudeMDEditor](https://marketplace.visualstudio.com/items?itemName=ClaudeMDEditor) | Visual UI to manage AI config files | GUI wrapper, no automation |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for open problems worth solving.
