#!/usr/bin/env bash
# build-claudeai-project-zip.sh
#
# Build a Claude.ai-compatible upload package for the *Claude.ai-only*
# variant of Context Update (`context-update-project`).
#
# This is the slim, single-layer variant designed specifically for
# Claude.ai's Project Instructions / Personal Preferences surfaces.
# It has no filesystem probes, no `.contextupdate.toml` step, and no
# apply loop — the deliverable is a copy-paste block.
#
# The other zip script (`build-claudeai-zip.sh`) packages the
# coding-agent skill (`context-update`) for users who want the full
# workflow on Claude.ai despite its no-write limitations. Pick whichever
# matches how you use Claude.ai.
#
# Output: dist/context-update-project-claudeai-<version>.zip
#
# Requires: bash, python3. (No external `zip` binary — we use Python's
# stdlib zipfile module so this works on stock Git Bash for Windows.)
#
# Invocation:
#   bash scripts/build-claudeai-project-zip.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_SRC="${REPO_ROOT}/skills/context-update-project"
DIST_DIR="${REPO_ROOT}/dist"

command -v python3 >/dev/null || { echo "python3 not found in PATH" >&2; exit 1; }
[ -d "$SKILL_SRC" ]           || { echo "skill source not found at $SKILL_SRC" >&2; exit 1; }
[ -f "$SKILL_SRC/SKILL.md" ]  || { echo "SKILL.md missing under $SKILL_SRC" >&2; exit 1; }

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${REPO_ROOT}/.claude-plugin/plugin.json")"
[ -n "$VERSION" ] || { echo "could not read version from .claude-plugin/plugin.json" >&2; exit 1; }

mkdir -p "$DIST_DIR"

OUT="${DIST_DIR}/context-update-project-claudeai-${VERSION}.zip"
rm -f "$OUT"

python3 - "$SKILL_SRC" "$OUT" <<'PY'
import os, sys, zipfile

src, out = sys.argv[1], sys.argv[2]
SKIP_NAMES = {'.DS_Store'}
SKIP_DIRS = {'__pycache__'}

with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if f in SKIP_NAMES or f.endswith('.swp'):
                continue
            abs_path = os.path.join(root, f)
            rel_path = os.path.relpath(abs_path, src)
            # Force forward slashes; Claude.ai's zip reader rejects
            # backslash entry names (APPNOTE.TXT 4.4.17.1).
            arcname = 'context-update-project/' + rel_path.replace(os.sep, '/').replace('\\', '/')
            z.write(abs_path, arcname)
PY

echo "Built: $OUT"
echo
echo "Upload steps (Claude.ai):"
echo "  1. Open claude.ai -> Customize (left sidebar) -> Skills."
echo "  2. Upload $OUT."
echo "  3. Enable the skill on the Projects where you want it."
echo
echo "Notes:"
echo "  - This is the Claude.ai-only variant. It targets Project Instructions"
echo "    and Personal Preferences (User style) — no filesystem, no config file."
echo "  - Trigger by running /context-update or asking 'run context update on this conversation'."
echo "  - Deliverable is always a copy-paste block. The skill never claims to have"
echo "    applied changes — you paste into Project settings manually."
