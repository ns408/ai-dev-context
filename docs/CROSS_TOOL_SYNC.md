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

| Tool | Config file | Header expectation | Memory handling |
|------|-------------|-------------------|-----------------|
| Claude Code | `.claude/CLAUDE.md` | Any markdown | References external memory file via `Read` instruction |
| Cursor | `.cursorrules` | Plain text / markdown | Must be inlined (no file reads) |
| Windsurf | `.windsurfrules` | Plain text / markdown | Must be inlined |
| Cline | `.clinerules` | Markdown | Must be inlined |
| GitHub Copilot | `.github/copilot-instructions.md` | Markdown | Must be inlined |
| OpenAI Codex | `AGENTS.md` | Markdown | Must be inlined |

The key difference: **Claude Code can read files at runtime** (`Read ~/.config/ai/context.md`). Every other tool needs the content inlined into its config file.

This means:
- Claude's config references the centralized memory file by path — memory stays in sync automatically
- All other tools need memory **inlined** into their config at generation time — a symlink can't do this

## What ai-config-sync.sh does

```
~/.config/ai/context.md          (Tier 1: global prefs, rarely changes)
~/.config/ai/projects/<repo>.md  (Tier 2: project memory, changes each session)
.ai/project.md                   (optional: in-repo project-specific rules)
          |
          v
    ai-config-sync.sh
          |
    ┌─────┴─────────────────────────────────┐
    │                                       │
.claude/CLAUDE.md              .cursorrules, .windsurfrules,
(reference by path)            .clinerules, AGENTS.md,
                               copilot-instructions.md
                               (memory inlined)
```

For Claude: generates a short file that `Read`-instructs Claude to load the canonical files. Memory stays live — no re-sync needed when memory changes.

For all other tools: inlines the full context + memory into one flat file. Re-run `ai-config-sync.sh` after significant memory updates to keep non-Claude tools current.

## Running the sync

```bash
# Set up a new project (all tools)
ai-config-sync.sh --all /path/to/project

# Update after memory changes (selective)
ai-config-sync.sh --cursor --windsurf .

# Just Claude (default, no flags needed)
ai-config-sync.sh .
```

The script is idempotent — it only writes files when content would change, and prints `unchanged:` for files that are already current.

## Gitignore handling

`ai-config-sync.sh` automatically adds generated files to `.gitignore`. These configs contain your personal machine specs and preferences — they should not be committed. Each developer runs the sync script once for their own environment.

The in-repo `CLAUDE.md` (your project instructions, architecture rules, etc.) is different — that one **should** be committed, because it's project-specific and shared with the team. Only the generated `.claude/CLAUDE.md` (which references your personal `~/.config/ai/context.md`) goes in `.gitignore`.

## Re-sync cadence

| Event | Action |
|-------|--------|
| New project | Run `ai-config-sync.sh --all .` once |
| Memory updated significantly | Run `ai-config-sync.sh --all .` to refresh non-Claude tools |
| Global context changed | Run `ai-config-sync.sh --all .` in all active projects |
| Claude only (daily use) | No re-sync needed — Claude reads memory file directly |
