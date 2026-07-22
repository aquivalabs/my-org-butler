#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

# Restore from cache if we have an auth URL for this alias. The DevHub keeps the
# scratch org alive for 30 days; only the runner-local SFDX auth file is missing
# across CI runs, so re-logging in is enough to skip provisioning.
AUTH_CACHE_FILE="/tmp/sfdx-auth-${SCRATCH_ORG_ALIAS}.url"
if [ -s "$AUTH_CACHE_FILE" ]; then
  echo "Found cached auth for $SCRATCH_ORG_ALIAS — attempting restore"
  if sf org login sfdx-url --alias "$SCRATCH_ORG_ALIAS" --set-default --sfdx-url-stdin < "$AUTH_CACHE_FILE" \
     && sf org display --target-org "$SCRATCH_ORG_ALIAS" >/dev/null 2>&1; then
    echo "Restored $SCRATCH_ORG_ALIAS — skipping provisioning"
    exit 0
  fi
  echo "Cached auth invalid (org expired or revoked) — falling through to fresh provisioning"
  rm -f "$AUTH_CACHE_FILE"
fi

# Portable in-place sed: BSD (macOS) needs an empty backup arg, GNU (Linux) doesn't.
sed_inplace() {
  if [ "$(uname)" = "Linux" ]; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# HEADLESS=true skips steps that require human interaction or a populated Data Library.
HEADLESS=${HEADLESS:-false}

# retrieval-staging is referenced in sfdx-project.json but git-ignored, so it's
# missing on a fresh checkout (e.g. CI). Create it so sf commands don't error.
mkdir -p retrieval-staging

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash your changes before running this script."
  exit 1
fi

echo "Updating tools"
# Note: 'npm install -g' reinstalls all 700 packages even when current — only run it when needed
if ! command -v sf >/dev/null || ! npm outdated --global @salesforce/cli >/dev/null; then
  npm install --global @salesforce/cli
fi
sf plugins update

if [ -z "$DEV_HUB_URL" ]; then
  echo "set default devhub user"
  execute sf config set target-dev-hub=$DEV_HUB_ALIAS

  echo "Deleting old scratch org"
  sf org delete scratch --no-prompt --target-org $SCRATCH_ORG_ALIAS
fi

NO_NAMESPACE_FLAG=""
if [ "$NAMESPACE" = "false" ]; then
  NO_NAMESPACE_FLAG="--no-namespace"
fi

echo "Creating scratch org"
execute sf org create scratch --alias $SCRATCH_ORG_ALIAS --set-default --definition-file ./config/project-scratch-def.json --duration-days 30 $NO_NAMESPACE_FLAG

echo "Make sure Org user is english"
sf data update record --sobject User --where "Name='User User'" --values "Languagelocalekey=en_US"

echo "Enabling Prompt Builder"
execute sf org assign permset --name EinsteinGPTPromptTemplateManager --name AgentPlatformBuilder

if [ "$NAMESPACE" = "false" ]; then
  echo "Deploying base package shims (no-namespace mode)"
  execute sf project deploy start --source-dir no-namespace --concise

  echo "Stripping namespace from source"
  sed_inplace 's/aquiva_os__//g; s/aquiva_os\.//g; s/"namespace": "aquiva_os"/"namespace": ""/' sfdx-project.json
  find force-app unpackaged agent-eval -type f \( -name "*.cls" -o -name "*.xml" -o -name "*.genAiPlannerBundle" -o -name "*.genAiPlugin-meta.xml" -o -name "*.yaml" \) -exec sed -i.bak 's/aquiva_os__//g; s/aquiva_os\.//g' {} + && find force-app unpackaged agent-eval -name "*.bak" -delete

  # Note: Restore source even if deploy fails — namespace stripping rewrites files in place
  trap 'echo "Restoring namespace in source"; git checkout -- sfdx-project.json force-app/ unpackaged/ agent-eval/' EXIT

  echo "Pushing changes to scratch org"
  execute sf project deploy start --source-dir force-app --concise --ignore-conflicts

  # Note: publish before unpackaged — AgentAccess permset references the Bot this creates
  echo "Publishing My Org Butler from Agent Script bundle"
  execute sf agent publish authoring-bundle --api-name MyOrgButler --skip-retrieve

  echo "Pushing unpackaged changes to scratch org"
  execute sf project deploy start --source-dir unpackaged --concise --ignore-conflicts

  echo "Restoring namespace in source"
  git checkout -- sfdx-project.json force-app/ unpackaged/ agent-eval/
  trap - EXIT
else
  echo "Installing dependencies"
  execute sf package install --package "app-foundations@LATEST" --publish-wait 3 --wait 10

  echo "Pushing changes to scratch org"
  execute sf project deploy start --source-dir force-app --concise --ignore-conflicts

  # Note: publish before unpackaged — AgentAccess permset references the Bot this creates
  echo "Publishing My Org Butler from Agent Script bundle"
  execute sf agent publish authoring-bundle --api-name MyOrgButler --skip-retrieve

  echo "Pushing unpackaged changes to scratch org"
  execute sf project deploy start --source-dir unpackaged --concise --ignore-conflicts
fi

echo "Assigning permissions"
execute sf org assign permset --name MyOrgButlerUser --name AgentAccess

echo "Activate My Org Butler"
execute bash `dirname $0`/activate-agent.sh MyOrgButler

echo "Deploying agent tests"
execute sf project deploy start --source-dir agent-eval --concise

echo "Creating Sample Data"
sf apex run --file scripts/create-sample-data.apex

echo "Uploading Proposal to Acme Opportunity"
OPP_ID=$(sf data query --query "SELECT Id FROM Opportunity WHERE Name='Acme Q1 Expansion Deal' LIMIT 1" --json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
sf data create file --file "scripts/data/proposal.pdf" --title "Acme Q1 Expansion Proposal" --parent-id "$OPP_ID"

echo "Populating test env files with record IDs"
CONTENT_DOC_ID=$(sf data query --query "SELECT Id FROM ContentDocument WHERE Title='Acme Q1 Expansion Proposal' LIMIT 1" --json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
if grep -q "^CONTENT_DOCUMENT_ID=" agent-eval/.env 2>/dev/null; then
  sed_inplace "s/^CONTENT_DOCUMENT_ID=.*/CONTENT_DOCUMENT_ID=${CONTENT_DOC_ID}/" agent-eval/.env
else
  echo "CONTENT_DOCUMENT_ID=${CONTENT_DOC_ID}" >> agent-eval/.env
fi

echo "Running Apex Tests"
sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Caching auth URL for reuse across CI runs"
sf org display --target-org "$SCRATCH_ORG_ALIAS" --verbose --json | jq -r .result.sfdxAuthUrl > "$AUTH_CACHE_FILE"

if [ "$HEADLESS" != "true" ]; then
  echo ""
  echo "=================== MANUAL SETUP ==================="
  echo " 1. Setup > Audit > Einstein Generative AI: enable Agent Analytics + Session Tracing"
  echo " 2. Skipped Tavily key? Set it on External Credential > TavilyApi"
  echo "===================================================="
  sf org open
  read -p "Press Enter when done (or to skip)..."

  echo "Setting up Data Cloud (library, files, index)"
  execute bash `dirname $0`/setup-data-cloud.sh scripts/data/policy.pdf

  echo "Running AgentRegression suite (Agentforce Studio runner)"
  mkdir -p /tmp/ae && rm -f /tmp/ae/*.json
  sf agent test run --api-name AgentRegression --wait 30 --result-format json > /tmp/ae/AgentRegression_run1.json 2>&1
fi

echo "Running SFX Scanner with Security, AppExchange and Coding Standards"
#sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file security-review/code-analyzer-security.csv --target force-app --target unpackaged
#sf code-analyzer run --config-file code-analyzer.yaml --rule-selector "PMD:OpinionatedSalesforce" --output-file security-review/code-analyzer-cleancode.csv --target force-app --target unpackaged
