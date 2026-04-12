# changelog-review

Interactive commit-by-commit walkthrough of git history. Summarizes API, web, schema, and business logic changes per commit. Designed for technical leads reviewing what shipped.

## Usage

```
/review-changes
```

Or trigger naturally: "walk me through changes since <commit>", "what shipped this week?"

## What it does

- Lists commits oldest-to-newest in a range
- Presents each commit one at a time with structured summary (module, endpoints, schema, business logic)
- Waits for "next" -- user controls the pace
- Supports questions, follow-up prompts, and quick fixes mid-review
- Catches up on new commits that land during the session
