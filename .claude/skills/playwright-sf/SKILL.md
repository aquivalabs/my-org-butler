---
name: playwright-sf
description: Drive a Salesforce Lightning org headlessly with Playwright MCP — reproduce bugs, verify UI changes, capture screenshot evidence. Invoked by sf-ticket-to-pr when a change is user-visible, or standalone.
---

# Playwright in a Salesforce Org

Used to look into the org as a user would: reproduce a reported bug, verify a UI change after deploy, capture screenshots for a PR. Selectors against Lightning's Shadow DOM are brittle — drive the page through the accessibility tree instead.

## Log in via the frontdoor URL

Don't script the login form. Ask the CLI for a one-time auto-login URL and open that:

    SCRATCH_URL=$(sf org open --url-only --target-org "$SCRATCH_ORG_ALIAS" --json | jq -r .result.url)

Open `SCRATCH_URL` with `playwright-cli open`. You land already logged in. The URL is single-use; if you need a second session, request another.

## Find things via the accessibility tree, not CSS

`playwright-cli snapshot` dumps the a11y tree of the current page with `ref=` handles. Read the snapshot, identify the element you want by its accessible name + role (e.g. "button Save", "textbox Subject"), then act on it by ref:

    playwright-cli click --ref <ref-from-snapshot>
    playwright-cli fill  --ref <ref-from-snapshot> --text "value"

Lightning composes shadow roots into the same a11y tree, so this works across LWC, Aura, and Visualforce without per-component selectors.

## Wait before you assert

Lightning pages spinner. Before every assertion: take a snapshot, scan for a stable anchor element you expect to be present (the record name, a section header, the Save button), and only then assert. If the anchor isn't there after two snapshots a few seconds apart, report `UI-INCONCLUSIVE` rather than `UI-FAIL` — flaky load ≠ broken feature.

## Capture evidence and put it on the PR

Every assertion writes a screenshot. Write to a path **inside the branch**
so the screenshots ride along with the commit and GitHub renders them inline
in the PR body by relative URL:

    mkdir -p ".verification/pr-$ISSUE_NUMBER"
    playwright-cli screenshot --filename ".verification/pr-$ISSUE_NUMBER/<scenarioId>.png" --full-page
    git add ".verification/pr-$ISSUE_NUMBER/<scenarioId>.png"

In the PR markdown (or the reply comment), embed each screenshot with a
caption that says what it proves:

    ## How it looks
    ![Home page with Daily Quote LWC rendering](./.verification/pr-12/home-after.png)

For bug repros, post the **before** and **after** as a pair so the reviewer
sees the broken state and the fixed state side by side.

Always pair the screenshots with the scratch-org auto-login URL (see
`sf-ticket-to-pr` Step 4) — "here's the screenshot" + "here's the org" is
what makes the work self-evidencing. Don't post one without the other.

## When the caller is `sf-ticket-to-pr`

Two shapes show up:

**Bug reproduction.** The ticket describes broken behaviour. Before writing any fix, open the org, walk to the broken state, snapshot + screenshot. Attach the repro evidence to the PR. After the fix deploys, re-run the same scenario and confirm it now passes. The "before" and "after" screenshots are the strongest signal a reviewer can get.

**Feature verification.** The ticket describes desired behaviour. After the change is deployed, derive scenarios from the acceptance criteria, run them, screenshot the passing state. Cap at five scenarios per PR — pick the headline ones, note the rest.

## Anti-patterns

- Logging in by filling the username/password form. Use the frontdoor URL.
- Asserting on CSS selectors that walk into Shadow DOM. Use a11y `ref=` handles.
- Marking a flaky load as `UI-FAIL`. Use `UI-INCONCLUSIVE` so Butler doesn't block a good PR on a Lightning hiccup.
- Running more than ~5 scenarios per PR. The CI budget isn't infinite; pick the ones that matter.
