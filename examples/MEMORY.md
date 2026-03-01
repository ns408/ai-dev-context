# Project Memory — my-cli-tool

This file is auto-injected by Claude Code at the start of every session.
Keep it under 200 lines. Architecture and rules live in CLAUDE.md.
This file covers current implementation state only.

---

## User Preferences

- Always use `bun` for package management, not npm or yarn
- Never auto-commit — always show diff and ask first
- Prefer editing existing files over creating new ones

---

## Implementation Status

### Phase 1 — Core CLI ✅
- `src/cli.ts` — entry point, argument parsing via `commander`
- `src/commands/init.ts` — `my-cli-tool init <name>` scaffolds a new project
- `src/commands/build.ts` — `my-cli-tool build` compiles + bundles via esbuild
- Tests: 42 passing, all in `tests/unit/`

### Phase 2 — Plugin system 🔄
- `src/plugins/loader.ts` — dynamic import of `*.plugin.ts` files from `.my-cli/plugins/`
- Plugin interface defined in `src/types.ts` — `Plugin { name, version, run(ctx) }`
- **Blocked**: Plugin hot-reload crashes on macOS when watching symlinked dirs (chokidar bug)
- Next step: file a chokidar issue; workaround is to use polling mode

### Phase 3 — Publish command ⏳
- Not started. Will call npm registry API to publish plugins as scoped packages.

### Backlog (do not work on without explicit instruction)
- B1: Windows support (path separator issues throughout)
- B2: Telemetry opt-in

---

## Key Technical Decisions

### esbuild over tsc for bundling
We compile with esbuild for 10x faster builds. Type-checking still runs separately via `tsc --noEmit`. This split means CI runs type-check + esbuild in parallel rather than sequentially.

### commander over yargs
Chose `commander` for smaller bundle size and simpler API. `yargs` has better built-in validation but the extra 40 KB wasn't worth it for a CLI tool.

### Dynamic plugin loading via `import()`
Plugins are loaded with `await import(pluginPath)` at runtime. This means no build step for plugins — users drop a `.plugin.ts` file and it works. Trade-off: requires `tsx` or `ts-node` in the user's env.

---

## Bugs Fixed

| Bug | Fix |
|-----|-----|
| `commander` exits process on `--help` in tests | Pass `{ exitOverride: true }` to `new Command()` in test mode |
| esbuild external plugin not found | Add `node_modules` to `external` array in esbuild config |
| chokidar symlink crash on macOS | Use `{ usePolling: true }` when `process.platform === 'darwin'` |

---

## Workflow Commands

```bash
# Install dependencies
bun install

# Run tests
bun test

# Build
bun run build

# Run CLI locally during development
bun run src/cli.ts init my-test-project

# Type-check only
bun run typecheck
```
