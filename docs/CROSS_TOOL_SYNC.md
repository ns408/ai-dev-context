# Cross-Tool Sync: Why Generation Over Symlinks

AI coding tools all read from different files in different formats. Keeping them in sync is a genuine maintenance burden.

## The symlink approach (common but limited)

Many developers symlink one master file to all tool-specific locations:

```bash
ln -s ~/.config/ai/context.md .cursorrules
ln -s ~/.config/ai/context.md .windsurfrules
```

This works if every tool reads the exact same format. In practice, they don't.

## Why tools need different formats

| Tool | Config file | Format | How context loads |
|------|-------------|--------|-------------------|
| Claude Code | `.claude/CLAUDE.md` | Markdown | `@path` syntax — file loaded at session start by Claude Code |
| Cursor | `.cursorrules` | Plain text / markdown | Must be inlined (no file loading at runtime) |
| Windsurf | `.windsurfrules` | Plain text / markdown | Must be inlined |
| Cline | `.clinerules` | Markdown | Must be inlined |
| GitHub Copilot | `.github/copilot-instructions.md` | Markdown | Must be inlined |
| OpenAI Codex | `AGENTS.md` | Markdown | Must be inlined |
| Kiro | `.kiro/steering/*.md` | YAML-frontmatter markdown | Per-file, loaded by Kiro natively |

The key difference: Claude Code supports `@path/to/file` syntax in CLAUDE.md. A line like `@~/.config/ai/context.md` causes Claude Code to load and expand that file at session start. Writing `Read ~/.config/ai/context.md` as plain text does not work — that is just advisory prose that Claude may or may not act on.

All other tools (except Kiro, which has its own format) need content inlined into their config files.

## What ai-config-sync.sh does

```
~/.config/ai/context.md          (global identity — your prefs, rarely changes)
.ai/project.md                   (optional per-project rules — committed to repo)
          |
          v
    ai-config-sync.sh
          |
    +-----+------------------------------------------+
    |                                                  |
.claude/CLAUDE.md                    .cursorrules, .windsurfrules,
(@~/.config/ai/context.md)           .clinerules, AGENTS.md,
                                     copilot-instructions.md
                                     (context inlined)
```

For Claude Code: generates a file with `@~/.config/ai/context.md`. The reference stays live — update your context.md and the next Claude Code session picks it up without re-running the script.

For all other tools: inlines the full context at generation time. Re-run `ai-config-sync.sh` after significant context updates to keep these files current.

## Running the sync

```bash
# Set up a new project (all tools)
ai-config-sync.sh --all /path/to/project

# Update after context changes (selective)
ai-config-sync.sh --cursor --windsurf .

# Just Claude Code (default, no flags needed)
ai-config-sync.sh .
```

The script is idempotent — it only writes files when content would change, and prints `unchanged:` for files that are already current.

## Gitignore handling

`ai-config-sync.sh` automatically adds generated files to `.gitignore`. These configs contain your personal machine specs and preferences — they should not be committed. Each developer runs the sync script once for their own environment.

The in-repo `CLAUDE.md` (your project instructions, architecture rules, etc.) is different — that one should be committed, because it's project-specific and shared with the team. Only the generated `.claude/CLAUDE.md` (which references your personal `~/.config/ai/context.md`) goes in `.gitignore`.

## Re-sync cadence

| Event | Action |
|-------|--------|
| New project | Run `ai-config-sync.sh --all .` once |
| Global context changed | Run `ai-config-sync.sh --all .` in active projects to refresh non-Claude tools |
| Claude Code only (daily use) | No re-sync needed — `@` reference loads context live |

---

## 2026 landscape

### MCP

Model Context Protocol joined the Linux Foundation in December 2025 as a founding project of the Agentic AI Foundation (AAIF), co-founded by Anthropic, Block, and OpenAI. MCP is now a vendor-neutral standard for tool and context integration.

### AGENTS.md adoption

`AGENTS.md` is an emerging cross-tool instruction file. Confirmed native readers as of April 2026:

| Tool | Reads AGENTS.md |
|------|----------------|
| OpenAI Codex CLI | Yes |
| Cursor | Yes |
| Windsurf | Yes |
| GitHub Copilot | Yes |
| Amp | Yes |
| Devin | Yes |
| Cline | No (proposed in issue #5033, not yet shipped) |
| Kiro | No (uses `.kiro/steering/` instead) |
| Claude Code | No (uses CLAUDE.md) |

`ai-config-sync.sh` generates `AGENTS.md` via `--codex`. This covers all confirmed readers.

### Built-in session memory

Several tools now capture session context automatically — no manual memory management needed:

| Tool | Auto-memory | Notes |
|------|-------------|-------|
| Claude Code | Yes (v2.1.59+) | Stored at `~/.claude/projects/<encoded>/memory/` |
| Windsurf | Yes | Cascade Memories, stored at `~/.codeium/windsurf/memories/` |
| GitHub Copilot | Yes (Pro/Pro+, March 2026) | Agentic Memory, repo-scoped, 28-day expiry |
| Cursor | No | Manual only |
| Cline | No | Manual Memory Bank |
| Kiro | Yes | Kiro Memory, stored in `.kiro/steering/` |

This project focuses on identity sync (deliberate preferences and conventions), not session memory capture. Those are different problems.
