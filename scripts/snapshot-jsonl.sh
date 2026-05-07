#!/usr/bin/env bash
# Snapshot the list of Claude Code session JSONLs before a run.
# report-ai-cost.sh diffs against this to find the run's new session.
set -euo pipefail
OUT=${1:-/tmp/jsonl-before.txt}
ls -1 "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | sort > "$OUT" || : > "$OUT"
echo "Snapshot: $OUT ($(wc -l < "$OUT") existing sessions)"
