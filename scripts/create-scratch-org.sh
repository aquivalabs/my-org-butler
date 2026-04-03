#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash your changes before running this script."
  exit 1
fi

echo "Updating tools"
npm install --global @salesforce/cli
sf plugins update

if [ -z "$DEV_HUB_URL" ]; then
  echo "set default devhub user"
  execute sf config set target-dev-hub=$DEV_HUB_ALIAS

  echo "Deleting old scratch org"
  sf org delete scratch --no-prompt --target-org $SCRATCH_ORG_ALIAS
fi

echo "Creating scratch org"
execute sf org create scratch --alias $SCRATCH_ORG_ALIAS --set-default --definition-file ./config/project-scratch-def.json --duration-days 30

echo "Make sure Org user is english"
sf data update record --sobject User --where "Name='User User'" --values "Languagelocalekey=en_US"

echo "Enabling Prompt Builder"
execute sf org assign permset --name EinsteinGPTPromptTemplateManager --name AgentPlatformBuilder

echo "Installing dependencies"
execute sf package install --package "app-foundations@LATEST" --publish-wait 3 --wait 10

echo "Stripping namespace for unnamespaced scratch org"
sed -i '' 's/aquiva_os__//g; s/aquiva_os\.//g; s/"namespace": "aquiva_os"/"namespace": ""/' sfdx-project.json
find force-app unpackaged regressions -type f \( -name "*.cls" -o -name "*.xml" -o -name "*.genAiPlannerBundle" -o -name "*.genAiPlugin-meta.xml" -o -name "*.yaml" \) -exec sed -i '' 's/aquiva_os__//g; s/aquiva_os\.//g' {} +

# Note: Restore source even if deploy fails — namespace stripping rewrites files in place
trap 'echo "Restoring namespace in source"; git checkout -- sfdx-project.json force-app/ unpackaged/ regressions/' EXIT

echo "Pushing changes to scratch org"
execute sf project deploy start --source-dir force-app --concise --ignore-conflicts

echo "Pushing unpackaged changes to scratch org"
execute sf project deploy start --source-dir unpackaged --concise --ignore-conflicts

echo "Deploying regressions"
execute sf project deploy start --source-dir regressions --concise


echo "Assigning permissions"
execute sf org assign permset --name MyOrgButlerUser --name AgentAccess

echo "Activate My Org Butler"
execute sf agent activate --api-name MyOrgButler

echo "Creating Sample Data"
sf apex run --file scripts/create-sample-data.apex

echo "Uploading Sample Files"
OPP_ID=$(sf data query --query "SELECT Id FROM Opportunity WHERE Name='Acme Q1 Expansion Deal' LIMIT 1" --json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
sf data create file --file "scripts/sample-company-document.pdf" --title "Sample Company Document" --parent-id "$OPP_ID"

echo "Populating agentforce-eval/.env with test record IDs"
CONTENT_DOC_ID=$(sf data query --query "SELECT Id FROM ContentDocument WHERE Title='Sample Company Document' LIMIT 1" --json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
cat > agentforce-eval/.env <<EOF
OPENAI_API_KEY=${OPENAI_API_KEY}
CONTENT_DOCUMENT_ID=${CONTENT_DOC_ID}
EOF

echo ""
echo "============================================"
echo " MANUAL STEP: Data Library Setup"
echo "============================================"
echo " The org is opening now. To enable 'Answer from Data Library':"
echo " 1. Go to Setup → Data Library"
echo " 2. Create a new Data Library named: CompanyDocuments"
echo " 3. Type: File"
echo " 4. Upload: scripts/sample-company-document.pdf"
echo "    (same PDF already attached to the Acme Opportunity)"
echo " 5. Create a search index and wait for it to complete"
echo " 6. Open Einstein Studio → Retrievers"
echo "    and copy the retriever API Name for this library/index"
echo "    (example: File_ADL_CompanyDocuments_1Cx_Bxk6b013004)"
echo " 7. Go to Setup → Custom Settings → Custom Setting → Manage,"
echo "    edit the record named DataLibraryRetriever, and set Value"
echo "    to that retriever API Name"
echo "============================================"
echo ""
sf org open
read -p "Press Enter when done (or to skip)..."

echo "Running Apex Tests"
sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Running Testing Center Tests"
sf agent test run --api-name Regression_Test --wait 10

echo "Running Promptfoo Agent Regression Tests"
cd agentforce-eval && npx promptfoo@latest eval -c agent-regression.yaml --env-file .env --env-file .env.salesforce && cd ..

echo "Running Promptfoo Prompt Template Regression Tests"
cd agentforce-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env --env-file .env.salesforce && cd ..

echo "Running SFX Scanner with Security, AppExchange and Coding Standards"
#sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file code-analyzer-security.csv --target force-app/main/default
#sf code-analyzer run --rule-selector "PMD:OpinionatedSalesforce" --output-file code-analyzer-cleancode.csv --target force-app/main/default