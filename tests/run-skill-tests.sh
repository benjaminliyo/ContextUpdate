#!/usr/bin/env bash
# Dispatch each pressure scenario as a subagent run, capture the transcript,
# and check it against the GREEN expectations.
#
# This script is a scaffold; the actual subagent invocation depends on the
# host (Claude Code CLI, a test harness, etc.). The expected-tokens grep
# pass is portable across hosts.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCENARIO_DIR="${SCRIPT_DIR}/pressure-scenarios"
TRANSCRIPT_DIR="${SCRIPT_DIR}/transcripts"
mkdir -p "$TRANSCRIPT_DIR"

# Required tokens that must appear in a GREEN transcript for any scenario.
REQUIRED_TOKENS=(
    "Finding"
    "Apply?"
)

# Per-scenario extra tokens.
declare -A SCENARIO_TOKENS
SCENARIO_TOKENS["01-config-flip"]="contradiction|jest|vitest"
SCENARIO_TOKENS["02-plan-supersession"]="superseded|error envelope"
SCENARIO_TOKENS["03-personal-vs-project"]="contradiction|outside project root"

run_scenario() {
    local name="$1"
    local scenario_path="${SCENARIO_DIR}/${name}.md"
    local transcript_path="${TRANSCRIPT_DIR}/${name}.txt"

    if [ ! -f "$scenario_path" ]; then
        echo "MISS  ${name}: scenario file not found"
        return 1
    fi

    # Placeholder: replace with the real subagent dispatch for your host.
    # For Claude Code, this is typically:
    #   claude --subagent --scenario "$scenario_path" > "$transcript_path"
    # Failing that, the developer can paste the transcript into
    # transcripts/<name>.txt and re-run this script to grade it.
    if [ ! -f "$transcript_path" ]; then
        echo "SKIP  ${name}: no transcript at ${transcript_path}"
        echo "      run the scenario manually and save the transcript there."
        return 2
    fi

    local missing=()
    for tok in "${REQUIRED_TOKENS[@]}"; do
        if ! grep -q -- "$tok" "$transcript_path"; then
            missing+=("$tok")
        fi
    done

    local extras="${SCENARIO_TOKENS[$name]:-}"
    if [ -n "$extras" ]; then
        IFS='|' read -r -a extra_arr <<< "$extras"
        for tok in "${extra_arr[@]}"; do
            if ! grep -q -- "$tok" "$transcript_path"; then
                missing+=("$tok")
            fi
        done
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        echo "PASS  ${name}"
        return 0
    else
        echo "FAIL  ${name}: missing tokens: ${missing[*]}"
        echo "      transcript: ${transcript_path}"
        return 1
    fi
}

fail=0
for name in 01-config-flip 02-plan-supersession 03-personal-vs-project; do
    run_scenario "$name" || fail=$((fail+1))
done

if [ "$fail" -ne 0 ]; then
    echo
    echo "${fail} scenario(s) failed or skipped. Inspect transcripts for"
    echo "rationalizations; tighten SKILL.md and re-run."
    exit 1
fi

echo "All scenarios passed."
