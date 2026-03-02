#!/usr/bin/env bash
# review-memory-write.sh — Prompt for manual review whenever MEMORY.md is written.
#
# Register as both a PreToolUse and PostToolUse hook in .claude/settings.json.
# See templates/settings.json in this repo for the configuration block.
#
# PreToolUse:  backs up MEMORY.md before any write so a diff is possible.
# PostToolUse: shows the diff and prompts: (a)pprove / (e)dit / (d)iscard.
#
# For any file that is not a MEMORY.md the script exits immediately.
set -euo pipefail

BACKUP_DIR="${TMPDIR:-/tmp}/ai-memory-review"

# --- Read and parse JSON from stdin ---

INPUT="$(cat)"

parse() {
    # Usage: parse 'dot.separated.key'
    export PARSE_KEY="$1"
    printf '%s\n' "$INPUT" | python3 -c "
import sys, json, os
try:
    d = json.load(sys.stdin)
    for k in os.environ.get('PARSE_KEY', '').split('.'):
        d = d.get(k, '') if isinstance(d, dict) else ''
    print(d if isinstance(d, str) else '')
except Exception:
    print('')
" 2>/dev/null || true
}

hook_event="$(parse 'hook_event_name')"
file_path="$(parse 'tool_input.file_path')"

# --- Only act on MEMORY.md files ---

if [[ "$(basename "$file_path")" != "MEMORY.md" ]]; then
    exit 0
fi

mkdir -p "$BACKUP_DIR"
backup_path="${BACKUP_DIR}/$(printf '%s' "$file_path" | tr '/' '_').bak"

# --- PreToolUse: save a backup before the write ---

if [[ "$hook_event" == "PreToolUse" ]]; then
    if [[ -f "$file_path" ]]; then
        cp "$file_path" "$backup_path"
    else
        # New file — create empty backup so diff shows everything as added
        : > "$backup_path"
    fi
    exit 0  # must exit 0 to allow the tool to proceed
fi

# --- PostToolUse: show diff and prompt ---

if [[ "$hook_event" != "PostToolUse" ]]; then
    exit 0
fi

# Require a TTY for interactive prompting; auto-approve if none is available
if [[ ! -e /dev/tty ]]; then
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MEMORY.md was modified — review before it becomes permanent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ -f "$backup_path" ]]; then
    diff -u "$backup_path" "$file_path" && echo "(no changes detected)" || true
else
    echo "(no backup found — showing full file)"
    cat "$file_path"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  a  Approve — keep changes as-is"
echo "  e  Edit    — open in \$EDITOR before approving"
echo "  d  Discard — restore the previous version"
echo ""

exec < /dev/tty
read -r -p "Choice [a/e/d, default a]: " choice

case "${choice,,}" in
    e|edit)
        "${EDITOR:-vi}" "$file_path" < /dev/tty > /dev/tty
        echo "  ✓ Memory saved after editing."
        rm -f "$backup_path"
        ;;
    d|discard)
        if [[ -f "$backup_path" ]]; then
            cp "$backup_path" "$file_path"
            rm -f "$backup_path"
            echo "  ✗ Changes discarded — MEMORY.md restored to previous version."
        else
            echo "  ! No backup available — cannot restore. File left as-is."
        fi
        ;;
    *)
        # Default: approve
        echo "  ✓ Changes approved."
        rm -f "$backup_path"
        ;;
esac

echo ""
