#!/bin/bash
# Activates the latest published version of an agent without the interactive
# version picker of `sf agent activate`.
set -e
AGENT=${1:-MyOrgButler}

VERSION_ID=$(sf data query --query "SELECT Id FROM BotVersion WHERE BotDefinition.DeveloperName='$AGENT' ORDER BY CreatedDate DESC LIMIT 1" --json | jq -r '.result.records[0].Id')
sf api request rest "/services/data/v66.0/connect/bot-versions/${VERSION_ID}/activation" --method POST --body '{"status":"Active"}' --header "Content-Type: application/json"
