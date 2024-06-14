#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

if [ -z "$DEV_HUB_URL" ]; then
  echo "set default devhub user"
  execute sf config set defaultdevhubusername=$DEV_HUB_ALIAS

  echo "Deleting old scratch org"
  sf org delete scratch --no-prompt --target-org $SCRATCH_ORG_ALIAS
fi

echo "Creating scratch org"
execute sf org create scratch --alias $SCRATCH_ORG_ALIAS --set-default --definition-file ./config/project-scratch-def.json --duration-days 30

echo "Pushing changes to scratch org"
execute sf force source push

echo "Assigning permissions"
execute sf force user permset assign --perm-set-name MyOrgButlerUser 

echo "Make sure Org user is english"
sf data update record --sobject User --where "Name='User User'" --values "Languagelocalekey=en_US"

echo "Running Apex Tests"
execute sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Running SFX Scanner with Security rules"
execute sf scanner run --engine pmd-appexchange --target force-app

echo "Running SFX Scanner with Clean code rules"
execute sf scanner run --target force-app --pmdconfig ./ruleset.xml --format table


