#!/usr/bin/env bash
# build-claudeai-zip.sh
#
# Build a Claude.ai-compatible upload package from the skill source.
#
# Claude.ai's Skills surface (Customize in the left sidebar -> Skills)
# accepts a .zip whose top-level
# entry is `context-update/SKILL.md` (+ the references/ subtree). It does
# NOT use hooks, slash commands, or plugin manifests — those are
# Claude Code / Codex / Cursor / Gemini concerns.
#
# Output: dist/context-update-claudeai-<version>.zip
#
# Requires: bash, python3. (No external `zip` binary — we use Python's
# stdlib zipfile module so this works on stock Git Bash for Windows.)
#
# Invocation:
#   bash scripts/build-claudeai-zip.sh
#
# On Windows, double-clicking a .sh file opens it in an editor instead of
# running it. Use Git Bash and prefix with `bash` as above.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_SRC="${REPO_ROOT}/skills/context-update"
DIST_DIR="${REPO_ROOT}/dist"

command -v python3 >/dev/null || { echo "python3 not found in PATH" >&2; exit 1; }
[ -d "$SKILL_SRC" ]           || { echo "skill source not found at $SKILL_SRC" >&2; exit 1; }
[ -f "$SKILL_SRC/SKILL.md" ]  || { echo "SKILL.md missing under $SKILL_SRC" >&2; exit 1; }

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${REPO_ROOT}/.claude-plugin/plugin.json")"
[ -n "$VERSION" ] || { echo "could not read version from .claude-plugin/plugin.json" >&2; exit 1; }

mkdir -p "$DIST_DIR"

OUT="${DIST_DIR}/context-update-claudeai-${VERSION}.zip"
rm -f "$OUT"

# Build the zip via Python — same layout as before
# (top-level dir is `context-update/`, containing SKILL.md and references/).
# Skip junk: .DS_Store, *.swp, __pycache__/.
python3 - "$SKILL_SRC" "$OUT" <<'PY'
import os, sys, zipfile

src, out = sys.argv[1], sys.argv[2]
SKIP_NAMES = {'.DS_Store'}
SKIP_DIRS = {'__pycache__'}

with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        # Prune skipped dirs in-place so os.walk doesn't recurse into them.
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if f in SKIP_NAMES or f.endswith('.swp'):
                continue
            abs_path = os.path.join(root, f)
            rel_path = os.path.relpath(abs_path, src)
            # Force forward slashes in archive paths regardless of platform
            # separator. Claude.ai's zip reader rejects backslash entry names
            # with "Zip file contains path with invalid characters" — the ZIP
            # spec (APPNOTE.TXT 4.4.17.1) requires '/' only.
            arcname = 'context-update/' + rel_path.replace(os.sep, '/').replace('\\', '/')
            z.write(abs_path, arcname)
PY

echo "Built: $OUT"
echo
echo "Upload steps (Claude.ai):"
echo "  1. Open claude.ai -> Customize (left sidebar) -> Skills."
echo "  2. Upload $OUT."
echo "  3. Enable the skill on the projects/conversations where you want it."
echo
echo "Notes:"
echo "  - Claude.ai does not support SessionStart hooks."
echo "  - Slash-command surface varies by client version - try /context-update"
echo "    first; otherwise invoke by message: \"run context-update on this conversation\"."
echo "  - The skill reads Project instructions, Personal preferences, and uploaded"
echo "    or pasted files from the conversation context, then emits a per-file"
echo "    copy-paste block you paste back into Claude.ai's UI."
