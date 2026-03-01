#!/usr/bin/env bash
# Link centralized AI project memory to IDE-specific locations.
#
# Usage:
#   ai-memory-link                  # Current directory
#   ai-memory-link /path/to/project # Specific project
#
# Creates a central memory file at ~/.config/ai/projects/<repo-name>.md
# and symlinks Claude Code's MEMORY.md to it. If an existing MEMORY.md
# has content, it is migrated to the central file first.
set -euo pipefail

CENTRAL_DIR="${HOME}/.config/ai/projects"
CLAUDE_PROJECTS="${HOME}/.claude/projects"

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# --- Detect repo name ---
get_repo_name() {
    local dir="$1"
    if git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
        local remote_url
        remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
        if [[ -n "$remote_url" ]]; then
            # Extract repo name from SSH or HTTPS URL, strip .git suffix
            basename "$remote_url" .git
            return
        fi
    fi
    # Fallback: directory basename
    basename "$dir"
}

# --- Encode path the way Claude Code does ---
encode_path() {
    local path="$1"
    # Replace / with - (Claude Code's encoding)
    echo "$path" | sed 's|/|-|g'
}

REPO_NAME="$(get_repo_name "$PROJECT_DIR")"
CENTRAL_FILE="${CENTRAL_DIR}/${REPO_NAME}.md"
ENCODED_PATH="$(encode_path "$PROJECT_DIR")"
CLAUDE_MEMORY_DIR="${CLAUDE_PROJECTS}/${ENCODED_PATH}/memory"
CLAUDE_MEMORY_FILE="${CLAUDE_MEMORY_DIR}/MEMORY.md"

mkdir -p "$CENTRAL_DIR"

echo "Project:  ${PROJECT_DIR}"
echo "Repo:     ${REPO_NAME}"
echo "Central:  ${CENTRAL_FILE}"
echo "Claude:   ${CLAUDE_MEMORY_FILE}"
echo ""

# --- Create or migrate central memory file ---
if [[ ! -f "$CENTRAL_FILE" ]]; then
    # Check if Claude Code has existing memory to migrate
    if [[ -f "$CLAUDE_MEMORY_FILE" ]] && [[ ! -L "$CLAUDE_MEMORY_FILE" ]] && [[ -s "$CLAUDE_MEMORY_FILE" ]]; then
        echo "  migrating: Claude Code MEMORY.md → ${CENTRAL_FILE}"
        cp "$CLAUDE_MEMORY_FILE" "$CENTRAL_FILE"
    else
        echo "  created:   ${CENTRAL_FILE} (empty)"
        printf '# Project Memory — %s\n' "$REPO_NAME" > "$CENTRAL_FILE"
    fi
else
    echo "  exists:    ${CENTRAL_FILE}"
fi

# --- Symlink Claude Code's MEMORY.md ---
mkdir -p "$CLAUDE_MEMORY_DIR"

if [[ -L "$CLAUDE_MEMORY_FILE" ]]; then
    current_target="$(readlink "$CLAUDE_MEMORY_FILE")"
    if [[ "$current_target" == "$CENTRAL_FILE" ]]; then
        echo "  unchanged: Claude symlink already correct"
    else
        rm "$CLAUDE_MEMORY_FILE"
        ln -s "$CENTRAL_FILE" "$CLAUDE_MEMORY_FILE"
        echo "  relinked:  Claude symlink → ${CENTRAL_FILE}"
    fi
elif [[ -f "$CLAUDE_MEMORY_FILE" ]]; then
    # Real file exists — back it up if it has content we haven't migrated
    if [[ -s "$CLAUDE_MEMORY_FILE" ]]; then
        backup="${CLAUDE_MEMORY_FILE}.bak.$(date +%Y%m%d)"
        cp "$CLAUDE_MEMORY_FILE" "$backup"
        echo "  backed up: ${backup}"
    fi
    rm "$CLAUDE_MEMORY_FILE"
    ln -s "$CENTRAL_FILE" "$CLAUDE_MEMORY_FILE"
    echo "  linked:    Claude MEMORY.md → ${CENTRAL_FILE}"
else
    ln -s "$CENTRAL_FILE" "$CLAUDE_MEMORY_FILE"
    echo "  linked:    Claude MEMORY.md → ${CENTRAL_FILE}"
fi

echo ""
echo "Done. Run 'ai-config-sync ${PROJECT_DIR}' to update IDE configs with memory."
