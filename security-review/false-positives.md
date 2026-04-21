# False Positives

## Salesforce Code Analyser

For every release we ran those recommended rulesets on the Code Analyser v5

```
sf code-analyzer run --rule-selector Recommended:Security, AppExchange --output-file code-analyzer-security.csv 
```

### ApexCRUDViolation - AgentMemory.cls:27, 81

**Status:** False Positive - The scanner flagged `delete newMemory` (line 27) and `upsert consolidated` (line 81) as missing CRUD validation.

This is a false positive because `AgentMemory` runs as a cross-user scheduled batch via `NightlyMemoryConsolidation`. `Memory__c` is an agent-managed object - end users have no CRUD permission on it, only the agent writes memories on their behalf. The DML operations use `delete as system` and `upsert as system` to make the system-mode intent explicit, and the class is only reachable from the batch, never from user-facing flows.

### AvoidHardcodedCredentialsInVarAssign - HeadlessAgent.cls:66

**Status:** False Positive - The scanner flagged `result.sessionId = 'mock-session-id'` as a hardcoded credential assignment.

The rule matches on the variable name (`sessionId`), not on semantics. The literal `'mock-session-id'` is assigned only inside the `Test.isRunningTest()` branch as a unit-test stub. It is never reachable from production code paths and has no security value.

### ApexFlsViolation (READ) - LoadCustomInstructions.cls:28

**Status:** False Positive - The Graph Engine flagged the SOQL on `Memory__c` as missing FLS validation.

The query has an explicit `WITH SYSTEM_MODE` clause. System mode is required here: the query reads `IsShared__c = true` memories authored by other users, which a user-mode query would filter out. `Memory__c` is agent-managed and users have no direct CRUD on it. Graph Engine does not always recognise the `WITH SYSTEM_MODE` access-level hint and therefore reports the query as if it ran in user mode.

### ApexFlsViolation (INSERT) - StoreCustomInstruction.cls:14

**Status:** False Positive - The Graph Engine flagged `insert as system memory` as missing FLS validation.

The DML already uses `as system`, which is the explicit opt-in to system-mode DML. The agent writes memories on behalf of users who have no direct CRUD on `Memory__c`. Graph Engine does not recognise the `as system` keyword and flags the insert as if it ran in user mode.

### ApexFlsViolation (READ, Unknown fields) - QueryRecordsWithSoql.cls:10

**Status:** False Positive - The Graph Engine could not resolve the parameter passed to the READ operation and requested confirmation of FLS checks.

The call uses `Database.query(input[0].dynamicSoqlQuery, AccessLevel.USER_MODE)`. User mode is enforced at runtime by the platform; all object- and field-level security checks run automatically against the current user's permissions. Because the query string itself is assembled from Agentforce input (dynamic SOQL), Graph Engine cannot statically resolve the referenced fields and therefore reports "Unknown" fields. The class is also annotated `with sharing` and relies on runtime enforcement rather than static analysis.

### ApexNullPointerException - DataLibrary.cls:149

**Status:** False Positive - The Graph Engine warned that `sourceRecordId.substringAfter('/')` might dereference a null object.

`sourceRecordId` originates from Data Cloud chunk rows via `SourceRecordId__c`, which is a required key field in every chunk row. In practice it is always populated. The retrieval path also wraps the entire loop in a `try/catch` that returns an empty result on any failure, so even a hypothetical null would not propagate to the caller as an NPE.
