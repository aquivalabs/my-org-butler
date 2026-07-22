#!/bin/bash
# Regenerates the static resources that ship the Agent Script and test definitions
# in the package (AiAuthoringBundle/AiTestingDefinition are not 2GP-packageable).
# Subscribers open /resource/AgentScript in the browser and copy the
# script into Agent Studio — so the copy must carry the aquiva_os__ namespace
# on all apex:// and generatePromptResponse:// targets.
set -e
cd "$(dirname $0)/.."

SRC=unpackaged/main/default/aiAuthoringBundles/MyOrgButler/MyOrgButler.agent
OUT_DIR=force-app/main/default/staticresources

sed -e 's|apex://|apex://aquiva_os__|g' \
    -e 's|generatePromptResponse://|generatePromptResponse://aquiva_os__|g' \
    "$SRC" > "$OUT_DIR/AgentScript.resource"

cp unpackaged/main/default/aiTestingDefinitions/AgentRegression.aiTestingDefinition-meta.xml "$OUT_DIR/AgentRegressionTest.resource"
cp unpackaged/main/default/aiTestingDefinitions/PromptRegression.aiTestingDefinition-meta.xml "$OUT_DIR/PromptRegressionTest.resource"

echo "Synced $(ls $OUT_DIR/{AgentScript,AgentRegressionTest,PromptRegressionTest}.resource | wc -l | tr -d ' ') static resources from source"
