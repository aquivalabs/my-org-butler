#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

echo "Set default devhub user"
execute sf config set target-dev-hub=$DEV_HUB_ALIAS

echo "List existing package versions"
sf package version list -p "$PACKAGE_NAME" --concise

echo "Create new package version"
PACKAGE_VERSION_OUTPUT=$(sf package version create -p "$PACKAGE_NAME" --installation-key-bypass --wait 40 --code-coverage -f config/project-scratch-def.json --json)
if [ $? -ne 0 ]; then
  echo "Error: Failed to create package version"
  echo "$PACKAGE_VERSION_OUTPUT"
  exit 1
fi

PACKAGE_VERSION=$(echo "$PACKAGE_VERSION_OUTPUT" | jq -r '.result.SubscriberPackageVersionId // empty')
if [ -z "$PACKAGE_VERSION" ] || [ "$PACKAGE_VERSION" = "null" ]; then
  echo "Error: Failed to extract package version ID"
  echo "Output: $PACKAGE_VERSION_OUTPUT"
  exit 1
fi

echo "Promote package version $PACKAGE_VERSION"
execute sf package version promote -p "$PACKAGE_VERSION" -n

echo "Install from: /packaging/installPackage.apexp?p0=$PACKAGE_VERSION"

if [ -n "$QA_ORG_ALIAS" ]; then
  if [ -n "$QA_ORG_URL" ]; then
    echo "Authenticate QA Org"
    echo "$QA_ORG_URL" | sf org login sfdx-url --sfdx-url-stdin -a "$QA_ORG_ALIAS"
  fi

  echo "Install in QA Org"
  execute sf package install -p "$PACKAGE_VERSION" -o "$QA_ORG_ALIAS" -b 30 -w 40 -r
fi