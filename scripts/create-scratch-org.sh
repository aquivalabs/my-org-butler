#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

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

echo "Creating Service Agent user"
execute sf apex run --file scripts/create-setup-data.apex

echo "Pushing changes to scratch org"
execute sf project deploy start --source-dir force-app --concise --ignore-conflicts

echo "Running Apex Tests"
sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Pushing unpackaged changes to scratch org"
execute sf project deploy start --source-dir unpackaged --concise --ignore-conflicts

echo "Assigning permissions"
execute sf org assign permset --name MyOrgButlerUser --name AgentAccess

echo "Activate My Org Butler"
execute sf agent activate --api-name MyOrgButler

echo "Deploying regressions"
execute sf project deploy start --source-dir regressions --concise

echo "Creating Sample Data"
sf apex run --file scripts/create-sample-data.apex

echo "Uploading Sample Files"
OPP_ID=$(sf data query --query "SELECT Id FROM Opportunity WHERE Name='Acme Q1 Expansion Deal' LIMIT 1" --json | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
sf data create file --file "scripts/Acme_NDA_2026.pdf" --title "Acme Corporation NDA 2026" --parent-id "$OPP_ID"

echo "Running Agent Tests"
sf agent test run --api-name Regression_Test --wait 10

echo "Running SFX Scanner with Security, AppExchange and Coding Standards"
sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file security-review/scans/code-analyzer-security.csv --target force-app/main/default
sf code-analyzer run --rule-selector "PMD:OpinionatedSalesforce" --output-file security-review/scans/code-analyzer-cleancode.csv --target force-app/main/default