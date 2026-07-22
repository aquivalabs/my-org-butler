#!/bin/bash
# Data Cloud setup: waits for provisioning, sets the Tavily key (if $TAVILY_API_KEY),
# creates the MyOrgButlerLibrary Data Library, uploads + indexes the given files.
set -e
FILES=${@:-scripts/data/policy.pdf}
ADL="/services/data/v66.0/einstein/data-libraries"

echo "Waiting for Data Cloud provisioning..."
until sf api request rest "$ADL" | jq -e '.libraries or .dataLibraries' >/dev/null 2>&1; do
  echo "  ...retrying in 60s"; sleep 60
done

if [ -n "$TAVILY_API_KEY" ]; then
  echo "Setting Tavily API key"
  sf api request rest "/services/data/v66.0/named-credentials/credential" --method POST --header "Content-Type: application/json" \
     --body "{\"externalCredential\":\"TavilyApi\",\"principalName\":\"ApiKey\",\"principalType\":\"NamedPrincipal\",\"credentials\":{\"ApiKey\":{\"value\":\"$TAVILY_API_KEY\",\"encrypted\":true}}}"
fi

echo "Creating Data Library"
LIB_ID=$(sf api request rest "$ADL" | jq -r '(.dataLibraries // .libraries // [])[] | select(.developerName=="MyOrgButlerLibrary") | .libraryId')
if [ -z "$LIB_ID" ]; then
  LIB_ID=$(sf agent adl create --name MyOrgButlerLibrary --developer-name MyOrgButlerLibrary --source-type sfdrive --index-mode enhanced --json | jq -r '.result.libraryId')
fi

echo "Uploading files to library $LIB_ID"
until sf api request rest "$ADL/$LIB_ID/upload-readiness?waitMaxTime=120000" | jq -e '.ready' >/dev/null 2>&1; do
  echo "  ...retrying in 60s"; sleep 60
done
for f in $FILES; do sf agent adl file add --library-id "$LIB_ID" --path "$f"; done

# Note: 'sf agent adl file add' never triggers indexing — kick it manually.
echo "Triggering indexing"
sf api request rest "$ADL/$LIB_ID/indexing" --method POST --header "Content-Type: application/json" \
   --body "$(sf api request rest "$ADL/$LIB_ID" | jq -c '{uploadedFiles: [.groundingSource.groundingFileRefs[] | {filePath, fileSize}]}')"

echo "Waiting for chunks..."
until sf apex run -f "$(dirname $0)/wait-for-chunks.apex" 2>&1 | grep -q 'USER_DEBUG.*READY'; do
  echo "  ...retrying in 60s"; sleep 60
done
