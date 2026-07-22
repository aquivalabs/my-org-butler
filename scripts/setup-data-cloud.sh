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
LIB_ID=$(sf api request rest "$ADL" | jq -r '(.dataLibraries // .libraries // [])[] | select(.developerName=="MyOrgButlerLibrary") | .libraryId' | head -n1)
if [ -z "$LIB_ID" ]; then
  LIB_ID=$(sf agent adl create --name MyOrgButlerLibrary --developer-name MyOrgButlerLibrary --source-type sfdrive --index-mode enhanced --json | jq -r '.result.libraryId')
fi

# Note: 'adl upload' (unlike 'adl file add') also triggers indexing and waits for the retriever.
echo "Uploading files to library $LIB_ID"
FILE_FLAGS=""; for f in $FILES; do FILE_FLAGS="$FILE_FLAGS --file $f"; done
sf agent adl upload --library-id "$LIB_ID" $FILE_FLAGS --wait 30

echo "Waiting for chunks..."
TRIES=0
until sf apex run -f "$(dirname $0)/wait-for-chunks.apex" 2>&1 | grep -q 'USER_DEBUG.*READY'; do
  TRIES=$((TRIES+1))
  if [ $TRIES -ge 30 ]; then echo "FAILED: no chunks after 30 minutes"; exit 1; fi
  echo "  ...retrying in 60s"; sleep 60
done
