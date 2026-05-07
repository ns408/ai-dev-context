# Global AI Context

Single source of truth for all AI coding assistants.
Managed by: ~/.config/ai/scripts/ai-config-sync.sh

## Machine

{{MACHINE_SPECS}}

<!-- Example:
- MacBook Pro M3 Pro, 36 GB RAM, 512 GB SSD, macOS Sequoia
- Shell: zsh
-->

## AI Tools Installed

{{AI_TOOLS_LIST}}

<!-- Example:
- **IDEs:** Cursor, Visual Studio Code, Windsurf, Kiro
- **IDE Plugins:** Cline, Claude Code, GitHub Copilot
- **Browser:** Arc
-->

## Runtime Management

- Python and Node.js versions are managed per project using **mise**.
- Never use system Python/Node. Check for `.mise.toml` in the project root first.
- If absent, run `mise use python@<version>` or `mise use node@<version>` before installing dependencies.
- If mise exec is not picking up site-packages outside a project directory, invoke Python via its full path: `~/.local/share/mise/installs/python/<version>/bin/python`.

## Collaboration Protocol

<!-- Optional but recommended. Defines how Claude should behave across all sessions. -->

### Conversation Modes
Declare the mode at the start of every response. Do not mix modes unless asked.
- **Explore** — Generating options, research, brainstorming. Nothing is decided. No implementation.
- **Decide** — Narrowing to clear recommendations with reasoning and trade-offs. Still no changes until permission.
- **Implement** — Only after explicit user permission. Execute agreed work, then report exactly what changed and stop.

### Permission Gate
Never make changes to files, code, or the project unless the user explicitly says one of:
"Go ahead and implement", "Do it", "Write that up", or "Make that change".
Ambiguous replies ("sounds good", "interesting", thumbs-up) do not count. If in doubt, ask.

## Coding Preferences

### Languages & Linting
- Python: format with black, lint with flake8, scan with bandit
- TypeScript/JavaScript: lint with eslint
- Shell: target POSIX-compatible bash; use shellcheck conventions (quote variables, use `[[ ]]`, avoid eval)
- IaC: Terraform with consistent naming (snake_case resources, kebab-case tags)

### Architecture
- Prioritize cloud-native, containerized code with Docker/K8s compatibility
- Prefer 12-factor app patterns (env-based config, stateless processes, disposable containers)
- Use 1Password CLI or pass for secrets — never hardcode or commit credentials

### Design Axiom — Balance
- Every addition must justify its cost across four dimensions: **completeness** (does it fill a real gap?), **security** (does it reduce attack surface?), **convenience** (does it save meaningful time?), and **resource cost** (memory, CPU, disk, network)
- When dimensions conflict, prefer: security > resource cost > convenience > completeness
- Periodically audit for bloat — remove anything that no longer earns its keep

### Quality
- Validate at system boundaries (user input, external APIs) — trust internal code
- Write tests for business logic and edge cases, not for framework glue
- Handle errors explicitly — no silent catches, always log or propagate

### Style
- Commit messages: imperative mood, concise subject (<70 chars), explain "why" not "what"
- PR descriptions: summary bullets + test plan
- Never add `Co-Authored-By` trailers to commit messages
- Never reference AI tools, AI assistance, or AI-generated content in committed code or commit messages
