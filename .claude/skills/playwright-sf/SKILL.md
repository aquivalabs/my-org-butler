---
name: playwright-sf
description: Drive a Salesforce Lightning org headlessly via the Playwright MCP server — reproduce bugs, verify UI changes, capture screenshot evidence. Invoked by sf-ticket-to-pr when a change is user-visible, or standalone.
---

# Playwright in a Salesforce Org

Use the Playwright MCP server (declared in `.mcp.json`) to look into the org as a user would: reproduce a reported bug, verify a UI change after deploy, capture screenshots for a PR. Selectors against Lightning's Shadow DOM are brittle — drive the page through the accessibility tree instead.

## Tools you have

The MCP server exposes (names as the agent sees them):

- `browser_navigate(url)` — open a URL
- `browser_snapshot()` — return the accessibility tree of the current page, with `ref` handles for every element
- `browser_click({ element, ref })` — click by `ref` from the snapshot
- `browser_type({ element, ref, text })` / `browser_fill_form` — type into a field by `ref`
- `browser_wait_for({ text | textGone | time })` — wait for content to appear/disappear or a fixed delay
- `browser_take_screenshot({ filename, fullPage })` — save a PNG
- `browser_press_key(key)` — keyboard input
- `browser_close()` — close the browser

## Log in via the frontdoor URL

Don't script the login form. Ask the CLI for a one-time auto-login URL and navigate to that:

    SCRATCH_URL=$(sf org open --url-only --target-org "$SCRATCH_ORG_ALIAS" --json | jq -r .result.url)

Then `browser_navigate(SCRATCH_URL)`. You land already logged in. The URL is single-use; if you need a second session, request another.

## Find things via the accessibility tree, not CSS

`browser_snapshot` dumps the a11y tree with `ref` handles. Read the snapshot, identify the element by its accessible name + role ("button Save", "textbox Subject"), then act on it by ref:

    browser_click({ element: "Save button", ref: "<ref-from-snapshot>" })
    browser_type({ element: "Subject field", ref: "<ref-from-snapshot>", text: "value" })

Lightning composes shadow roots into the a11y tree, so this works across LWC, Aura, and Visualforce without per-component selectors.

## Wait before you assert

Lightning pages spinner. Before every assertion: `browser_wait_for({ text: "<known anchor>" })` for a stable anchor element you expect (the record name, a section header, the Save button). Then `browser_snapshot()`. If the anchor never shows up after two reasonable waits, report `UI-INCONCLUSIVE` rather than `UI-FAIL` — flaky load ≠ broken feature.

## Capture evidence and put it on the PR

Every assertion writes a screenshot. Write to a path **inside the branch** so the screenshots ride along with the commit and GitHub renders them inline in the PR body by relative URL:

    mkdir -p ".verification/pr-$ISSUE_NUMBER"
    # then:
    browser_take_screenshot({ filename: ".verification/pr-$ISSUE_NUMBER/<scenarioId>.png", fullPage: true })
    git add -f ".verification/pr-$ISSUE_NUMBER/<scenarioId>.png"

`-f` because `.verification/` is gitignored on `main`; we force-add it on the PR branch and it disappears when the branch is deleted on merge.

Embed each screenshot with an **absolute raw GitHub URL** — GitHub Markdown
in PR bodies and comments does **not** render relative image paths. Use:

    https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>

Concretely:

    ## Verified
    ![Home page with accountGreeter LWC rendering](https://raw.githubusercontent.com/aquivalabs/my-org-butler/fix/issue-103/.verification/pr-103/account-after.png)

Substitute `<owner>/<repo>` from `$GITHUB_REPOSITORY`, `<branch>` from
`git branch --show-current`. Relative paths look right in `git diff` but
render as broken-image placeholders in the actual PR body — never use them
for embedded screenshots.

For bug repros, post the **before** and **after** as a pair.

Always pair screenshots with the scratch-org auto-login URL (see `sf-ticket-to-pr` Step 4) — "here's the screenshot" + "here's the org" is the self-evidencing pattern.

## When the caller is `sf-ticket-to-pr`

Two shapes:

**Bug reproduction.** The ticket describes broken behaviour. Before writing any fix, navigate to the broken state, snapshot + screenshot. Attach the repro evidence. After the fix deploys, re-run the same scenario and confirm it now passes.

**Feature verification.** After the change is deployed, walk through the acceptance criteria, screenshot the passing state. Cap at five screenshots per PR.

## Video recording

The MCP server cannot record video. When the full interaction sequence — user input → system processes → response appears — is the thing being proven, write a short Node.js script and run it via Bash. Playwright's `recordVideo` context option captures the session and flushes the file to disk when the context is closed.

**Step 1 — locate the Chromium binary and the playwright module.** The workflow already installed Chromium via `npx playwright install --with-deps chromium`. Find it before writing the script:

    CHROME=$(find ~/.cache/ms-playwright /root/.cache/ms-playwright \
      ~/Library/Caches/ms-playwright \
      -type f \( -name 'chrome' -o -name 'chromium' \) 2>/dev/null | head -1)
    echo "Chromium: $CHROME"

Letting Playwright auto-resolve the executable path fails when the version in the npx cache doesn't match what was installed. Always pass the found path as `executablePath`.

For the `import`, install playwright temporarily so the module resolves cleanly:

    npm install --no-save playwright

**Step 2 — write the script.** Only four variables to fill in:

```js
import { chromium } from 'playwright';
import { mkdir, readdir } from 'fs/promises';

const CHROME     = '<path from the find command above>';
const FRONTDOOR  = '<sf org open --url-only --json | jq -r .result.url>';
const VIDEO_DIR  = '.verification/pr-<N>';
const EXPECTED   = '<word or phrase that will appear on the page when the interaction is done>';

await mkdir(VIDEO_DIR, { recursive: true });
const browser = await chromium.launch({ headless: true, executablePath: CHROME });
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
  recordVideo: { dir: VIDEO_DIR, size: { width: 1280, height: 720 } },
});
const page = await context.newPage();

await page.goto(FRONTDOOR, { waitUntil: 'domcontentloaded' });
await page.waitForURL('**/lightning/**', { timeout: 20000 });

// Navigate and interact.
// Discover element names and roles via browser_snapshot() first, then use getByRole / getByText.
// Nothing should be hardcoded here — discover at runtime.

// Stop the moment the expected phrase is visible — no fixed sleep, no networkidle
await page.waitForFunction(
  expected => document.body.innerText.includes(expected),
  EXPECTED,
  { timeout: 90000, polling: 1000 }
);
await page.waitForTimeout(3000); // let the response settle visually

await context.close(); // flushes the video file to disk
await browser.close();

const [video] = (await readdir(VIDEO_DIR)).filter(f => f.endsWith('.webm'));
console.log(`webm: ${VIDEO_DIR}/${video}`);
```

**Step 3 — convert and commit alongside screenshots:**

    ffmpeg -i .verification/pr-<N>/<file>.webm -c:v libx264 -preset fast -crf 22 -movflags +faststart \
      .verification/pr-<N>/session.mp4 -y
    git add -f .verification/pr-<N>/session.mp4

**Step 4 — link from the PR body.** GitHub Markdown does not auto-embed video from `raw.githubusercontent.com`, but the browser plays it natively when the reviewer clicks through — one click, new tab, plays immediately:

    [Watch recording](https://raw.githubusercontent.com/<owner>/<repo>/<branch>/.verification/pr-<N>/session.mp4)

**Finding elements for the script.** Before writing the script, take a `browser_snapshot()` via the MCP tools to see the current a11y tree. Read the accessible names and roles of the elements you need, then use `getByRole` / `getByText` in the script. Never hardcode element names — Lightning page composition varies by org configuration.

## Anti-patterns

- Logging in by filling the username/password form. Use the frontdoor URL.
- Picking elements by CSS selectors. Use a11y `ref` handles from `browser_snapshot`.
- Marking a flaky load as `UI-FAIL`. Use `UI-INCONCLUSIVE`.
- More than ~5 screenshots per PR. CI budget isn't infinite; pick the ones that prove the change.
- Verifying without ever opening the page in the org. If the change is user-visible and you didn't `browser_navigate` to it, the verify step didn't happen.
- Using `waitForLoadState('networkidle')` on Lightning pages — it never settles. Wait for a specific element instead.
- Recording video with the MCP tools — they cannot. Use the Node.js script above.
- Using a fixed sleep or timeout to decide when to stop recording. Wait for the expected response text, then close immediately.
