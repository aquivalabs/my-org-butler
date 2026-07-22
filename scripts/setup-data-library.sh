#!/bin/bash
# Creates the MyOrgButlerLibrary Data Library, uploads the given files, triggers
# indexing, and waits until chunks are queryable.
#
# Note: `sf agent adl file add` uploads but never triggers indexing (only the create
# flow does) — without the manual POST to /indexing, files sit unindexed forever.
# Note: The chunk DMO name is org-specific (ADL_<random>_..._chunk__dlm), so it is
# discovered via ExploreDataCloud instead of hardcoded.
set -e
FILES=${@:-scripts/data/policy.pdf}
ADL="/services/data/v66.0/einstein/data-libraries"

LIB_ID=$(sf api request rest "$ADL" | jq -r '(.dataLibraries // .libraries // [])[] | select(.developerName=="MyOrgButlerLibrary") | .libraryId' 2>/dev/null)
if [ -z "$LIB_ID" ]; then
  LIB_ID=$(sf agent adl create --name MyOrgButlerLibrary --developer-name MyOrgButlerLibrary --source-type sfdrive --json | jq -r '.result.libraryId')
fi
echo "Library: $LIB_ID"

for f in $FILES; do
  sf agent adl file add --library-id "$LIB_ID" --path "$f"
done

INDEX_BODY=$(sf api request rest "$ADL/$LIB_ID" | jq -c '{uploadedFiles: [.groundingSource.groundingFileRefs[] | {filePath, fileSize}]}')
sf api request rest "$ADL/$LIB_ID/indexing" --method POST --body "$INDEX_BODY" --header "Content-Type: application/json"

echo "Waiting for Data Library chunks..."
until sf apex run -f /dev/stdin 2>&1 <<'APEX' | grep -q 'READY'
ExploreDataCloud.Input inp = new ExploreDataCloud.Input();
inp.scope = 'summary';
String resp = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ inp })[0].response;
String chunkDmo;
for(String tok : resp.split('"')) {
    if(tok.endsWith('_chunk__dlm')) { chunkDmo = tok; break; }
}
if(chunkDmo != null) {
    ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
    q.sql = 'SELECT COUNT(*) FROM ' + chunkDmo;
    ConnectApi.CdpQueryOutputV2 r = ConnectApi.CdpQuery.queryANSISqlV2(q);
    if(r.data != null && !r.data.isEmpty() && String.valueOf(r.data[0].rowData[0]) != '0') System.debug('READY');
}
APEX
do echo "  ...retrying in 30s"; sleep 30; done
