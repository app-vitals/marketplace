# Testing: research

Manual test plan for the research plugin.

---

## /research Command Tests

### Test 1: Project With Docs

**Setup:** Open a project that has a `docs/` directory with multiple markdown files (e.g., vitals-os).

**Command:** `/research add retry logic to the payment service API calls`

**Verify:**
- [ ] Agent discovers docs directory
- [ ] Agent selects relevant files (not all files)
- [ ] Output is structured with "Research Results" format
- [ ] Output includes "Relevant Project Docs", "Recommended Approach", "Key Constraints"
- [ ] No raw file contents in output — only distilled summaries
- [ ] Intermediate reasoning does not appear in main session

---

### Test 2: Project Without Docs

**Setup:** Open a project that has no `docs/`, `documentation/`, or `doc/` directory.

**Command:** `/research implement a caching layer`

**Verify:**
- [ ] Plugin detects no docs directory
- [ ] Informs user and proceeds with web-only research
- [ ] Web search results are summarized, not raw
- [ ] Output still follows structured format

---

### Test 3: Web Search Triggered

**Setup:** Open a project with docs that don't cover the topic.

**Command:** `/research integrate with Stripe webhooks`

**Verify:**
- [ ] Agent reads local docs first
- [ ] Agent identifies gap (Stripe not covered locally)
- [ ] Web search is triggered and results are summarized
- [ ] Output clearly indicates web research was performed

---

### Test 4: Simple Solution Bias

**Command:** `/research implement authentication for the API`

**Verify:**
- [ ] Output leads with simplest, most standard approach
- [ ] Complex alternatives mentioned only if genuinely warranted
- [ ] Language favors proven/established patterns

---

## Sub-Agent Isolation Tests

### Test 5: Read-Only Enforcement

**Command:** `/research refactor the billing module`

**Verify:**
- [ ] Agent does not create or modify any files
- [ ] Agent does not prompt the user with questions
- [ ] Only the final structured output appears in the session

---

## /research-docs Command Tests

### Test 6: Full Audit With Existing Docs

**Setup:** Open a project with a `docs/` directory that has some but not all modules documented (e.g., vitals-os).

**Command:** `/research-docs`

**Verify:**
- [ ] Detects project structure (modules, services)
- [ ] Lists existing docs as CURRENT
- [ ] Identifies missing docs (e.g., api-accounts.md)
- [ ] Identifies stale docs (if any references are outdated)
- [ ] Presents audit summary before writing anything
- [ ] Waits for user confirmation

---

### Test 7: Single Module Focus

**Setup:** Open a project with a `docs/` directory.

**Command:** `/research-docs accounts`

**Verify:**
- [ ] Focuses only on the accounts module
- [ ] Reads accounts source code (routes, models, handlers)
- [ ] Generates doc following existing naming convention
- [ ] Does not touch other docs

---

### Test 8: No Docs Directory

**Setup:** Open a project with no `docs/` directory.

**Command:** `/research-docs`

**Verify:**
- [ ] Creates `docs/` directory
- [ ] Identifies all modules as missing docs
- [ ] Generates docs following sensible defaults
- [ ] Updates CLAUDE.md references if applicable

---

### Test 9: Style Detection

**Setup:** Open a project with existing docs that use a specific style (tables, ASCII diagrams, etc.).

**Command:** `/research-docs`

**Verify:**
- [ ] Generated docs match the naming convention of existing docs
- [ ] Generated docs use the same heading structure and content patterns
- [ ] Does not overwrite or reformat existing current docs

---

## Regression Checklist

Before shipping:
- [ ] All test scenarios pass
- [ ] Plugin installs cleanly via `/plugin install`
- [ ] No conflicts with other marketplace plugins
- [ ] Version bumped in all required locations
