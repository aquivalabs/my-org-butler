#!/usr/bin/env bash
# Report AI cost for one Claude Code run.
#
# - Diffs JSONL transcripts under ~/.claude/projects/ vs a pre-run snapshot to
#   find this run's session, runs ccusage on it, and emits a one-line footer
#   plus an issue-level rollup in a sticky comment.
#
# Required env:
#   GH_TOKEN, GITHUB_REPOSITORY
#   WORKFLOW_NAME    "ticket-to-pr" | "pr-feedback"
#   MODEL            e.g. claude-sonnet-4-6
#   JSONL_BEFORE     path to pre-run snapshot file (created via snapshot-jsonl.sh)
# Optional env (at least one of PR/COMMENT must be set; ISSUE drives rollup):
#   PR_NUMBER        append footer to this PR's body
#   COMMENT_ID       append footer to this issue/PR comment
#   ISSUE_NUMBER     update sticky rollup on this issue

set -euo pipefail

: "${GH_TOKEN:?}"; : "${GITHUB_REPOSITORY:?}"
: "${WORKFLOW_NAME:?}"; : "${MODEL:?}"; : "${JSONL_BEFORE:?}"

STICKY_MARKER="<!-- ai-spend-tracker -->"
RUN_MARKER_PREFIX="<!-- run "

# 1. Find this run's session JSONL by diffing snapshots.
shopt -s nullglob
mapfile -t after_files < <(ls -1 "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | sort)
printf '%s\n' "${after_files[@]}" > /tmp/jsonl-after.txt
NEW_FILE=$(comm -13 "$JSONL_BEFORE" /tmp/jsonl-after.txt | tail -n 1)

if [ -z "$NEW_FILE" ]; then
  echo "::warning::No new Claude Code session JSONL found — skipping cost report."
  exit 0
fi

SESSION_ID=$(basename "$NEW_FILE" .jsonl)
echo "Session: $SESSION_ID"

# 2. Run ccusage and parse cost + tokens.
USAGE_JSON=$(npx -y ccusage@latest session --id "$SESSION_ID" --json 2>/dev/null || echo '{}')

read -r COST INPUT OUTPUT CACHE_R CACHE_W TOTAL <<< "$(echo "$USAGE_JSON" | jq -r '
  (.sessions[0] // .) as $s |
  [
    ($s.totalCost // 0),
    ($s.inputTokens // 0),
    ($s.outputTokens // 0),
    ($s.cacheReadTokens // 0),
    ($s.cacheCreationTokens // 0),
    ($s.totalTokens // 0)
  ] | @tsv' | tr '\t' ' ')"

# Short model name (drop "claude-" prefix for display).
SHORT_MODEL=${MODEL#claude-}

human_tokens() {
  local n=$1
  if (( n >= 1000000 )); then printf "%.1fM" "$(echo "$n/1000000" | bc -l)"
  elif (( n >= 1000 )); then printf "%dk" "$(( n / 1000 ))"
  else printf "%d" "$n"; fi
}

COST_FMT=$(printf "%.2f" "$COST")
TOTAL_H=$(human_tokens "$TOTAL")
INPUT_H=$(human_tokens "$INPUT")
OUTPUT_H=$(human_tokens "$OUTPUT")
CACHE_H=$(human_tokens "$CACHE_R")

FOOTER=$(cat <<EOF

---
<!-- ai-run wf=$WORKFLOW_NAME model=$MODEL cost=$COST_FMT tokens=$TOTAL -->
🤖 \`$SHORT_MODEL\` · \$$COST_FMT · $TOTAL_H tokens ($INPUT_H in / $OUTPUT_H out / $CACHE_H cache) · $WORKFLOW_NAME
EOF
)

# 3. Append footer to PR body or comment.
append_to_pr_body() {
  local n=$1
  local body
  body=$(gh pr view "$n" --repo "$GITHUB_REPOSITORY" --json body --jq .body)
  printf '%s%s' "$body" "$FOOTER" | gh pr edit "$n" --repo "$GITHUB_REPOSITORY" --body-file -
}

append_to_comment() {
  local id=$1
  local body
  body=$(gh api "repos/$GITHUB_REPOSITORY/issues/comments/$id" --jq .body)
  local new
  new=$(printf '%s%s' "$body" "$FOOTER")
  gh api -X PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$id" -f body="$new" >/dev/null
}

if [ -n "${PR_NUMBER:-}" ]; then
  append_to_pr_body "$PR_NUMBER"
  echo "Appended cost footer to PR #$PR_NUMBER"
fi
if [ -n "${COMMENT_ID:-}" ]; then
  append_to_comment "$COMMENT_ID"
  echo "Appended cost footer to comment $COMMENT_ID"
fi

# 4. Update sticky rollup on the issue.
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

# Append the new run record.
NEW_RUN_LINE="<!-- run wf=$WORKFLOW_NAME model=$MODEL cost=$COST_FMT tokens=$TOTAL -->"
RUN_LINES=$(printf '%s\n%s' "$RUN_LINES" "$NEW_RUN_LINE" | sed '/^$/d')

# Build table rows + totals from accumulated run records.
TOTAL_COST=0
TOTAL_TOKENS=0
RUN_COUNT=0
TABLE_ROWS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  wf=$(   echo "$line" | sed -n 's/.*wf=\([^ ]*\).*/\1/p')
  m=$(    echo "$line" | sed -n 's/.*model=\([^ ]*\).*/\1/p')
  c=$(    echo "$line" | sed -n 's/.*cost=\([^ ]*\).*/\1/p')
  t=$(    echo "$line" | sed -n 's/.*tokens=\([^ ]*\).*/\1/p')
  RUN_COUNT=$((RUN_COUNT + 1))
  TOTAL_COST=$(echo "$TOTAL_COST + $c" | bc -l)
  TOTAL_TOKENS=$((TOTAL_TOKENS + t))
  short_m=${m#claude-}
  t_h=$(human_tokens "$t")
  TABLE_ROWS+="| $RUN_COUNT | $wf | $short_m | \$$c | $t_h |"$'\n'
done <<< "$RUN_LINES"

TOTAL_COST_FMT=$(printf "%.2f" "$TOTAL_COST")
TOTAL_TOKENS_H=$(human_tokens "$TOTAL_TOKENS")

STICKY_BODY=$(cat <<EOF
$STICKY_MARKER
## 🤖 AI spend on this issue

**Total: \$$TOTAL_COST_FMT · $TOTAL_TOKENS_H tokens · $RUN_COUNT run(s)**

| # | Workflow | Model | Cost | Tokens |
|---|---|---|---|---|
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
