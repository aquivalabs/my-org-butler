#!/bin/bash
# Re-scan force-app + unpackaged, diff against a baseline directory, write delta.
# Usage: scripts/analyzer-check.sh <baseline-dir> [--fail-on-delta]
# Writes /tmp/analyzer-delta.txt. Sets GitHub Actions output `has_delta`.

set -eo pipefail
BASELINE="$1"
FAIL_ON_DELTA="${2:-}"
POST=/tmp/analyzer-post
mkdir -p "$POST"

sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file "$POST/code-analyzer-security.csv" --target force-app --target unpackaged || true
sf code-analyzer run --config-file .claude/skills/sf-code-analyzer/code-analyzer.yaml --rule-selector "PMD:OpinionatedSalesforce" --output-file "$POST/code-analyzer-cleancode.csv" --target force-app --target unpackaged || true

key() { awk -F'","' 'NR>1 {print $1"|"$5"|"$10}' "$1" 2>/dev/null | sort -u; }
{
  diff=$(comm -23 <(key "$POST/code-analyzer-cleancode.csv") <(key "$BASELINE/code-analyzer-cleancode.csv"))
  [ -n "$diff" ] && { echo "=== NEW clean-code findings ==="; echo "$diff"; }
  diff=$(comm -23 <(key "$POST/code-analyzer-security.csv") <(key "$BASELINE/code-analyzer-security.csv"))
  [ -n "$diff" ] && { echo "=== NEW security findings ==="; echo "$diff"; }
} > /tmp/analyzer-delta.txt

if [ -s /tmp/analyzer-delta.txt ]; then
  cat /tmp/analyzer-delta.txt
  [ -n "$GITHUB_OUTPUT" ] && echo "has_delta=true" >> "$GITHUB_OUTPUT"
  [ "$FAIL_ON_DELTA" = "--fail-on-delta" ] && exit 1
else
  [ -n "$GITHUB_OUTPUT" ] && echo "has_delta=false" >> "$GITHUB_OUTPUT"
fi
