# My Org Butler Branch Memory

Last updated: 2026-02-13

## Goal

Migrate My Org Butler from old Agentforce configuration patterns to Agent Script (`.agent`) with a single topic and multiple actions.

## Required Reading

- Coding conventions and implementation standards live in:
  - `AGENTS.md`
- Treat `AGENTS.md` as authoritative for Apex style, test structure, naming, and PMD expectations.

## Migration Context

- We are actively refactoring and validating Agent Script behavior in a namespaced scratch-org setup.
- Current source of truth for blockers and quirks is:
  - `.claude/skills/agentforce/references/known-issues.md`

## What We Tried

1. Reworked `MyOrgButler.agent` toward single-topic orchestration with multiple actions.
2. Updated action targets to namespaced Apex targets (`apex://aquiva_os__...`).
3. Fixed prompt action input naming/typing to match Agent Script expectations.
4. Ran phased deployment of core metadata (excluding known problematic paths/metadata types when needed).
5. Upgraded Salesforce CLI and agent plugin.
6. Investigated failures via CLI debug logs and Salesforce Agent Script recipes issues.

## What Is Proven

1. Deploying core metadata from repository paths works.
2. In this namespaced scratch org, non-namespaced Apex targets can pass `validate` but fail `publish`.
3. The current main blocker is publish-stage internal failure after successful validation in some configurations.
4. Local source tracking can be corrupted by deploys from temporary copied paths, producing `UnsafeFilepathError`.

## Current Blockers

- `sf agent publish authoring-bundle --api-name MyOrgButler` can fail with:
  - `Internal Error, try again later`
- This is tracked in known issues with reproducible details and links.

## Practical Guidance for This Branch

- Treat `validate` and `publish` as different gates; validate success is not enough.
- For namespaced orgs here, use namespaced `apex://` targets.
- Avoid deploy workflows that copy source into temp directories.
- Keep the known-issues file updated with reproducible steps for Salesforce reporting.
