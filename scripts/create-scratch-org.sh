#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

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
execute sf org assign permset --name EinsteinGPTPromptTemplateManager --name CopilotSalesforceAdmin

echo "Installing dependencies"
execute sf package install --package "app-foundations@LATEST" --publish-wait 3 --wait 10

echo "Pushing changes to scratch org"
execute sf project deploy start --source-dir force-app 
execute sf project deploy start --source-dir unpackaged

echo "Assigning permissions"
execute sf org assign permset --name MyOrgButlerUser 

echo "Running Apex Tests"
sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Running Agentforce Tests"
sf agent test run --api-name RegressionSuite --wait 10

echo "Running SFX Scanner with Security, AppExchange and Coding Standards"
sf code-analyzer run --rule-selector Recommended:Security, AppExchange --output-file code-analyzer-security.csv 
sf code-analyzer run --rule-selector PMD:OpinionatedSalesforce --output-file code-analyzer-cleancode.csv --target force-app/main/default