---
name: sf-code-analyzer
description: Run Salesforce Code Analyzer on Apex, Trigger, Flow, or metadata files. Use after writing or modifying .cls, .trigger, .xml, or flow files. Also use when asked to scan, lint, or check code quality.
argument-hint: "file, directory, security, cleancode, or blank for full scan"
---

# Salesforce Code Analyzer

Run code analysis with smart rule selection based on project type.

## Determine the target

- If `$ARGUMENTS` is a file or directory path, scan that path
- If files were just created or modified in this session, scan those specific files
- If no target is obvious, scan `force-app/main/default`

## Determine which scans to run

First check if the user explicitly asked for a specific scan:
- `$ARGUMENTS` contains "security" → security scan only
- `$ARGUMENTS` contains "cleancode" → clean code scan only

If no explicit choice, **detect the project type** to decide:

1. Read `sfdx-project.json` in the project root
2. Look for managed package signals:
   - `namespace` field is set (non-empty)
   - Package entries with `versionName` / `versionNumber`
   - A `security-review/` directory exists
   - Project name or path suggests AppExchange (e.g. contains "package", "managed", "appexchange")
3. Decision:
   - **Managed package detected** → run both security and clean code scans
   - **No package signals** (scratch org project, unlocked package, loose source) → run clean code scan only

When in doubt, just run clean code. Security scans are slow and noisy on projects that will never go through AppExchange review.

## Security scan (AppExchange rules)

```bash
sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file security-review/scans/code-analyzer-security.csv --target <TARGET>
```

## Clean code scan (opinionated PMD rules)

Uses the bundled [pmd-ruleset.xml](pmd-ruleset.xml) via [code-analyzer.yaml](code-analyzer.yaml).

```bash
sf code-analyzer run --rule-selector "PMD:OpinionatedSalesforce" --output-file code-analyzer-cleancode.csv --target <TARGET>
```

## After scanning

- Report findings grouped by severity (1 = critical, 5 = info)
- For each finding: file, line, rule name, and the message
- If no findings: confirm the code is clean
- Don't auto-fix without asking — just report

## False positives

When a finding is a false positive, suppress it in code with a comment explaining why:

```java
// Note: Input is required=true in schema — Agentforce won't call without it
@SuppressWarnings('PMD.MissingNullCheckOnSoqlVariable')
```

Document recurring false positives in `security-review/false-positives.md` if the file exists.
