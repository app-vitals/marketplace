---
name: triage-dependabot-pr
description: Analyze a Dependabot PR and post a patrol-style risk assessment comment. Extracted from the patrol GitHub Action. Use for single-PR triage or as a building block in bulk workflows.
user-invocable: true
argument-hint: "<pr-number>"
allowed-tools:
  - Bash
---

# Triage a Dependabot PR

Triage Dependabot PR: $ARGUMENTS

## Steps

### 1. Fetch PR context

```bash
gh pr view $ARGUMENTS --json number,title,body,author,headRefName,baseRefName,files,url
gh pr checks $ARGUMENTS --json name,status,conclusion 2>/dev/null || true
```

Extract:
- `title` — the PR title (e.g. "Bump axios from 1.6.0 to 1.7.0")
- `body` — Dependabot's description of the change
- `author` — should be `dependabot[bot]`
- `files` — changed files (usually package.json, package-lock.json, or yarn.lock)
- CI check statuses

### 2. Fetch the diff

```bash
gh pr diff $ARGUMENTS
```

Look at the actual version bumps — what changed, how many semver levels.

### 3. Analyze risk

Apply this triage rubric:

**Recommendation options:**
- `merge` — safe patch/minor update, no breaking changes, low risk
- `review` — significant version bump, possible breaking changes, or security-relevant; needs human eyes
- `hold` — known breaking change, deprecated package, or requires code changes before merging

**Flags to assess:**
- `breakingChange` — major version bump (X.0.0 → Y.0.0), or Dependabot body explicitly mentions breaking changes
- `securityRelevant` — CVE mentioned in body, or security-focused package (e.g. `helmet`, `bcrypt`, `jsonwebtoken`)
- `productionImpact` — package is in `dependencies` (not `devDependencies`); used in production paths

**Heuristics:**
- Patch bump (x.y.Z → x.y.Z+1) → almost always `merge` unless security-flagged
- Minor bump within same major (x.Y.z → x.Y+1.z) → usually `merge`, check for deprecation warnings in body
- Major bump (X.y.z → X+1.y.z) → usually `review` or `hold`; read the body carefully
- If Dependabot body references a CVE → `review` minimum; flag `securityRelevant`
- `devDependencies` only → lower production risk; usually `merge` or `review`

### 4. Check for existing patrol comment

```bash
gh pr view $ARGUMENTS --json comments --jq '.comments[] | select(.body | contains("<!-- patrol -->")) | .id'
```

If a patrol comment exists, note its ID — you'll replace it (delete first, then post fresh).

To delete:
```bash
gh api repos/{owner}/{repo}/issues/comments/{comment_id} -X DELETE
```

### 5. Post the triage comment

Format the comment exactly like this:

```
### {icon} Patrol: {label}

**{summary}**

{flags}

{reasoning}

<sub>🏔️ [patrol](https://github.com/app-vitals/patrol) · claude-sonnet-4-6</sub><!-- patrol -->
```

Where:
- `{icon}`: ✅ for merge, ⚠️ for review, 🛑 for hold
- `{label}`: "Safe to merge" / "Needs review" / "Hold — action required"
- `{summary}`: one sentence, e.g. "Bumps axios from 1.6.0 to 1.7.0 — minor release, no breaking changes."
- `{flags}`: space-separated, only include applicable: `🔴 Breaking change`, `🔒 Security relevant`, `🏭 Production impact`
- `{reasoning}`: 2-3 sentences explaining the recommendation

Post with:
```bash
gh pr comment $ARGUMENTS --body "..."
```

### 6. Report back

Return a summary:
```
PR #<number>: <title>
Recommendation: <merge|review|hold>
Flags: <flags or "none">
Comment posted ✓
```

## Notes

- The `<!-- patrol -->` HTML comment at the end of the comment body is the marker used to find and replace existing patrol comments.
- If CI is failing for reasons unrelated to the dependency bump (e.g. a pre-existing flaky test), note it in reasoning but don't let it change the recommendation.
- When in doubt, prefer `review` over `merge` — it's safe.
