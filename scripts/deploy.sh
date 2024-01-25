#!/bin/bash

# Validation parameter comes as True if checked
if [ "$1" = "True" ]; then
	echo "Running validation deployment"
	sfdx force:source:deploy -p "force-app" --wait 60 --checkonly --testlevel RunLocalTests  --verbose --ignorewarnings --json  > results.json
	cat results.json

	# Fail is the validation deployment has failed
    DEPLOYMENT_STATUS=$(cat results.json | jq -r '.result.status')
    if [[ "$DEPLOYMENT_STATUS" = "" || "$DEPLOYMENT_STATUS" = "null" || "$DEPLOYMENT_STATUS" = "Failed" ]]; then
        echo "Failed Validation Deployment, check logs for more information"
        exit 1
    else
        echo "Successful Validation Deployment"
    fi

	echo "Verifying coverage for each modified class or trigger"
	echo y | sfdx plugins:install nakama-plugin-sfdx
	NON_TEST_CLASSES=$((egrep -wrliL '@IsTest|public interface' force-app --include \*.cls --include \*.trigger || echo "") | xargs -rL 1 basename | sed 's/.cls//g' | sed 's/.trigger//g' | paste -sd "," -)
	echo 'Coverage to be checked in' $NON_TEST_CLASSES
	if [ $NON_TEST_CLASSES ]; then
		echo 'Verifying coverage with nps'
    	sfdx nps:coverage:verify --path results.json --required-coverage 80 --classes $NON_TEST_CLASSES
		if [[ $? -eq 1 ]]; then
  			echo "Failure: Missing Coverage"
  			exit 1
  		fi
    fi
else
	# RUN_TEST_PARAMETER is ignored if it is not a validation only deployment
	sfdx force:source:deploy -p "force-app" --wait 60 --verbose --ignorewarnings
fi
