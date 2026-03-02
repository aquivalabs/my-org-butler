#!/bin/bash
source `dirname $0`/config.sh

echo "Clearing scheduled plans..."

sf apex run --target-org $SCRATCH_ORG_ALIAS << 'EOF'
for(CronTrigger ct : [SELECT Id FROM CronTrigger]) {
    System.abortJob(ct.Id);
}
delete [SELECT Id FROM Plan__c];
System.purgeOldAsyncJobs(Date.today().addDays(1));
EOF

echo "Done. Scheduled jobs, plans, and async history cleared."
