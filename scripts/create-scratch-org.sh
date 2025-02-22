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

echo "Pushing changes to scratch org"
execute sf project deploy start

echo "Assigning permissions"
execute sf org assign permset --name MyOrgButlerUser 

echo "Make sure Org user is english"
sf data update record --sobject User --where "Name='User User'" --values "Languagelocalekey=en_US"

echo "Running Apex Tests"
execute sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

sf package install --package 04tHs000000W2H2 --publish-wait 5 --wait 10 --target-org $SCRATCH_ORG_ALIAS

# echo "Running SFX Scanner with Security, AppExchange and Coding Standards"
# sf code-analyzer run --rule-selector Security, AppExchange --output-file ./code-analyzer/output/code-analyzer-security.csv --output-file ./code-analyzer/output/code-analyzer-security.html
# sf code-analyzer run --rule-selector PMD --config-file ./code-analyzer-config.yml --output-file ./code-analyzer/code-analyzer-cleancode.csv --output-file ./code-analyzer/code-analyzer-cleancode.html
# sf scanner run dfa --output-file ./code-analyzer/output/graph-engine.csv --target ./ --projectdir ./ --category Security
