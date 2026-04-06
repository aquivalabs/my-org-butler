# Agentic now — Tips and Tricks to make the best of Agentforce

Robert Soesemann · Aquiva · CzechDreamin May 29, 2026
Demo repo: github.com/aquivalabs/my-org-butler


## Format

Scrollable HTML presentation (not PPTX). File: `CzechDreamin-AgenticNow.html`
- Full-viewport slides with CSS scroll-snap
- Arrow key navigation, slide counter
- Must look like PowerPoint at 100% browser zoom
- Aquiva branding (logo says "AQUIVA" — no "Labs")
- Skill file: `aquiva-slides.skill` documents the HTML approach, brand, layout rules
- CzechDreamin will add their own branding (no conference bar needed)


## Current Slide Titles (in HTML)

0. **Cover** — "Agentic now"
1. **Intro** — Why these tips, My Org Butler, fork it tonight
2. **Tip 1** — "Bold generic actions over fearful hardcoded ones"
3. **Tip 2** — "Use APIs to get close to code execution"
4. **Tip 3** — "Semantic queries on structured data with Data Cloud"
5. **Tip 4** — "Ground your prompts in your files" *(blue accent slide)*
6. **Tip 5** — "Your entire doc library as context"
7. **Tip 6** — "Let your agent improve itself with memory"
8. **Tip 7** — "Go headless — agentic means autonomous" *(purple accent slide)*
9. **Closing** — QR code + repo link


## Tip Slide Structure

Each tip slide now has:
- **Top:** Icon + "TIP N" label + short title (keyword phrase, not a sentence)
- **Middle:** Two-column layout — bullets on left, image placeholder on right
- **Bottom:** "IN MY ORG BUTLER" footer — concrete implementation with action names

Image placeholders are dashed boxes describing what screenshot goes there. Replace with actual screenshots later.

Titles are still being refined. Robert wants them to sound like tips/advice, with important keywords.


## Content Per Tip

### Tip 1: Bold generic actions over fearful hardcoded ones
- Trust the LLM. 2 generic actions beat 20 narrow ones.
- Org Butler: `ExploreOrgSchema` + `QueryRecordsWithSoql`
- Demo: "Which opportunity should I work on next?"

### Tip 2: Use APIs to get close to code execution
- Every REST endpoint is a function call. Chain enough = programming.
- Code-interpreter power but sandboxed — no arbitrary code.
- Org Butler: `CallRestApi`, `CallMetadataApi`, `CallToolingApi`, `CallGitHubApi` + External Services
- Demo: GitHub repo operations via Apex vs External Services
- **TODO Anmol:** External Services version of GitHub integration

### Tip 3: Semantic queries on structured data with Data Cloud
- "Find deals similar to Acme" — no WHERE clause can express "similar"
- Data Cloud hybrid retrievers, vector embeddings on CRM fields
- Demo: ranked similar Opportunities
- **TODO Anmol:** Data Cloud retriever with hybrid search on Opportunities

### Tip 4: Ground your prompts in your files
- Ungrounded agent invents answers with confidence
- Prompt Templates attach files/records, Flex templates control tone/format
- Three flavors: single file, record context, doc library search
- Org Butler: `AnswerFromFiles`
- Demo: Upload SOW → summarize deliverables → cite payment terms
- **TODO Anmol:** Consolidate into single `AnswerFromFiles` action

### Tip 5: Your entire doc library as context
- Grounding at scale: 200 docs, user remembers "something about refunds"
- Data Cloud hybrid search: keyword + semantic vectors
- Org Butler: Data Cloud file retriever + Vectorize fallback
- Demo: Find refund policy section by meaning, not filename
- **TODO Anmol:** Data Cloud file retriever with hybrid search index

### Tip 6: Let your agent improve itself with memory
- Every conversation starts from scratch — brilliant consultant with amnesia
- Persist preferences, decisions, ongoing tasks across sessions
- Org Butler: `AgentMemory` + `LoadCustomInstructions`
- Demo: Remember preferences → new session applies them silently

### Tip 7: Go headless — agentic means autonomous
- Chat is step one. Real pattern: no user, just triggers and schedules
- Interactive agents = demo, autonomous agents = product
- Org Butler: `HeadlessAgent` + `PlanForLater`
- Demo: "Every Monday, check stale opps and Slack me" → show the notification


## Visual Status

- Logos: cropped "AQUIVA" PNGs (base64 embedded), dark + light versions
- Icons: inline SVGs per tip slide
- Background watermark numbers: large decorative 1-7 on each tip slide
- Image placeholders: dashed boxes describing future screenshots
- Text sized for PowerPoint-scale (titles 3-4rem, bullets 2.4rem)
- Two accent slides: Tip 4 blue gradient, Tip 7 purple gradient


## What's Next

- [ ] Robert to refine titles further (they're close but may need tweaks)
- [ ] Replace image placeholders with actual screenshots from demos
- [ ] Anmol TODOs: External Services GitHub, Data Cloud retrievers
- [ ] Robert may want to reconsider whether tips 4+5 should merge
- [ ] Final text pass on bullets (currently from master plan, needs tightening)
