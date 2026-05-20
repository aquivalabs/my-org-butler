#!/usr/bin/env bash
# Report AI cost for one Claude Code run.
#
# Reads the action's execution_file output (a JSON array of SDK messages),
# pulls cost + per-token-type usage from the result message, and updates an
# issue-level sticky rollup comment. Cost lives only in the rollup — no
# footers are appended to human comments or PR bodies.
#
# Required env:
#   GH_TOKEN, GITHUB_REPOSITORY
#   WORKFLOW_NAME    "ticket-to-pr" | "pr-feedback"
#   MODEL            e.g. claude-sonnet-4-6
#   EXECUTION_FILE   path emitted by anthropics/claude-code-action (steps.<id>.outputs.execution_file)
#   ISSUE_NUMBER     update sticky rollup on this issue
#   CYCLE_ID         groups triage + execute of one @butler mention into one row
#                    (use $GITHUB_RUN_ID — same value across both jobs in a run)
#   TRIGGER          the event that started the cycle (e.g. issue_comment)

set -euo pipefail

: "${GH_TOKEN:?}"; : "${GITHUB_REPOSITORY:?}"
: "${WORKFLOW_NAME:?}"; : "${MODEL:?}"; : "${EXECUTION_FILE:?}"
: "${CYCLE_ID:?}"; : "${TRIGGER:?}"

STICKY_MARKER="<!-- ai-spend-tracker -->"
RUN_MARKER_PREFIX="<!-- run "

if [ ! -s "$EXECUTION_FILE" ]; then
  echo "::warning::EXECUTION_FILE missing or empty — skipping cost report."
  exit 0
fi

# Pull the result message (last one with type=result) and extract cost + usage.
read -r COST INPUT OUTPUT CACHE_R CACHE_W <<< "$(jq -r '
  [.[] | select(.type == "result")] | last as $r |
  [
    ($r.total_cost_usd // 0),
    ($r.usage.input_tokens // 0),
    ($r.usage.output_tokens // 0),
    ($r.usage.cache_read_input_tokens // 0),
    ($r.usage.cache_creation_input_tokens // 0)
  ] | @tsv' "$EXECUTION_FILE" | tr '\t' ' ')"

TOTAL=$(( INPUT + OUTPUT + CACHE_R + CACHE_W ))

human_tokens() {
  local n=$1
  if (( n >= 1000000 )); then printf "%.1fM" "$(echo "$n/1000000" | bc -l)"
  elif (( n >= 1000 )); then printf "%dk" "$(( n / 1000 ))"
  else printf "%d" "$n"; fi
}

COST_FMT=$(printf "%.2f" "$COST")

# Update sticky rollup on the issue.
if [ -z "${ISSUE_NUMBER:-}" ]; then
  exit 0
fi

# Find existing sticky comment.
STICKY_ID=$(gh api "repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"$STICKY_MARKER\")) | .id" | head -n 1)

# Collect existing run records from sticky body (if any).
RUN_LINES=""
if [ -n "$STICKY_ID" ]; then
  EXISTING=$(gh api "repos/$GITHUB_REPOSITORY/issues/comments/$STICKY_ID" --jq .body)
  RUN_LINES=$(echo "$EXISTING" | grep "^$RUN_MARKER_PREFIX" || true)
fi

# Append the new run record. cycle= groups triage + execute of one @butler
# mention so they collapse into a single table row; trigger= names the event
# the human used. Old records without cycle= are skipped when rebuilding.
NEW_RUN_LINE="<!-- run cycle=$CYCLE_ID trigger=$TRIGGER cost=$COST_FMT tokens=$TOTAL -->"
RUN_LINES=$(printf '%s\n%s' "$RUN_LINES" "$NEW_RUN_LINE" | sed '/^$/d')

# Aggregate by cycle: sum cost + tokens across all stage records sharing a
# cycle id, preserving first-seen order so the table reads chronologically.
declare -a CYCLE_ORDER=()
declare -A CYCLE_TRIGGER=() CYCLE_COST=() CYCLE_TOKENS=()
while IFS= read -r line; do
  [ -z "$line" ] && continue
  cyc=$(echo "$line" | sed -n 's/.*cycle=\([^ ]*\).*/\1/p')
  [ -z "$cyc" ] && continue
  trg=$(echo "$line" | sed -n 's/.*trigger=\([^ ]*\).*/\1/p')
  c=$(  echo "$line" | sed -n 's/.*cost=\([^ ]*\).*/\1/p')
  t=$(  echo "$line" | sed -n 's/.*tokens=\([^ ]*\).*/\1/p')
  if [ -z "${CYCLE_TRIGGER[$cyc]+set}" ]; then
    CYCLE_ORDER+=("$cyc")
    CYCLE_TRIGGER[$cyc]="$trg"
    CYCLE_COST[$cyc]="0"
    CYCLE_TOKENS[$cyc]=0
  fi
  CYCLE_COST[$cyc]=$(echo "${CYCLE_COST[$cyc]} + $c" | bc -l)
  CYCLE_TOKENS[$cyc]=$(( ${CYCLE_TOKENS[$cyc]} + t ))
done <<< "$RUN_LINES"

TOTAL_COST=0
TOTAL_TOKENS=0
TABLE_ROWS=""
ROW_NUM=0
for cyc in "${CYCLE_ORDER[@]}"; do
  ROW_NUM=$((ROW_NUM + 1))
  cc=$(printf "%.2f" "${CYCLE_COST[$cyc]}")
  tt=${CYCLE_TOKENS[$cyc]}
  TOTAL_COST=$(echo "$TOTAL_COST + $cc" | bc -l)
  TOTAL_TOKENS=$((TOTAL_TOKENS + tt))
  TABLE_ROWS+="| $ROW_NUM | ${CYCLE_TRIGGER[$cyc]} | \$$cc | $(human_tokens "$tt") |"$'\n'
done

TOTAL_COST_FMT=$(printf "%.2f" "$TOTAL_COST")
TOTAL_TOKENS_H=$(human_tokens "$TOTAL_TOKENS")

STICKY_BODY=$(cat <<EOF
$STICKY_MARKER
## 🤖 AI spend on this issue

**Total: \$$TOTAL_COST_FMT · $TOTAL_TOKENS_H tokens · $ROW_NUM cycle(s)**

| # | Trigger | Cost | Tokens |
|---|---|---|---|
$TABLE_ROWS
$RUN_LINES
EOF
)

if [ -n "$STICKY_ID" ]; then
  gh api -X PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$STICKY_ID" -f body="$STICKY_BODY" >/dev/null
  echo "Updated sticky rollup on issue #$ISSUE_NUMBER (comment $STICKY_ID)"
else
  gh api -X POST "repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/comments" -f body="$STICKY_BODY" >/dev/null
  echo "Created sticky rollup on issue #$ISSUE_NUMBER"
fi
