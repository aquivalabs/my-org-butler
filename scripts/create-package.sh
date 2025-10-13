#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}

if [ -z "$secrets.DEV_HUB_URL" ]; then
  echo "set default devhub user"
  execute sf config set defaultdevhubusername=$DEV_HUB_ALIAS
fi

echo "List existing package versions"
sf package version list -p $PACKAGE_NAME --concise

echo "Copy bot template from unsupported"
mkdir -p force-app/main/default/botTemplates
cp -R unsupported/botTemplates/* force-app/main/default/botTemplates/

echo "Create new package version"
PACKAGE_VERSION="$(execute sf package version create -p $PACKAGE_NAME --installation-key-bypass --wait 40 --code-coverage -f config/project-scratch-def.json --json | jq '.result.SubscriberPackageVersionId' | tr -d '"')"

echo "Clean up bot template"
rm -rf force-app/main/default/botTemplates

echo "Promote package version $PACKAGE_VERSION"
sf package version promote -p $PACKAGE_VERSION -n

echo "Install from: /packaging/installPackage.apexp?p0=$PACKAGE_VERSION"

if [ $QA_ORG_ALIAS ]; then
  if [ $secrets.QA_URL ]; then
    echo "Authenticate QA Org"
    echo $secrets.QA_URL | sf org login sfdx-url --sfdx-url-stdin -a "$QA_ORG_ALIAS"
  fi

  echo "Install in QA Org"
  execute sf package install -p $PACKAGE_VERSION -o "$QA_ORG_ALIAS" -b 30 -w 40 -r
fi