# CI Gate Reference

After PR creation, update the branch from main and monitor GitHub Actions CI checks before proceeding. This applies in both standalone and merge-mode.

## 11b.1. Update from Main

Merge the latest main into the PR branch to satisfy branch protection rules:

```
git fetch origin main
git merge origin/main
```

If the merge **succeeds** (no conflicts):

Check whether the merge actually brought in new commits:
```
git diff HEAD @{1} --quiet
```
If no changes (exit code 0 = already up to date), skip the push — CI is already running against the current code. Proceed directly to 11b.2.

If there are changes:
```
git push
```
The push triggers new CI runs against the updated code. Proceed to 11b.2.

If the merge produces **conflicts**: do NOT commit the merge. Instead, abort it (`git merge --abort`) and jump directly to 11b.4 (Fix Loop) with the conflict details as the failure context. The fix subagent will run `git merge origin/main`, resolve the conflicts, commit, and push.

## 11b.2. Wait for Checks

```
gh pr checks {pr-number} --watch
```

Use a **10-minute timeout** for this command (Bash tool `timeout: 600000`). If the command times out, treat it as a failure.

**No CI configured:** If `gh pr checks {pr-number}` returns no checks (empty output), skip the rest of Step 11b and proceed to Step 12. Print:
```
⏭ No CI checks configured — skipping CI gate
```

**All checks pass:** Print the following and proceed to Step 12:
```
✓ CI checks passed
```

**Any check fails:** Continue to 11b.3.

## 11b.3. Collect Failure Logs

1. Get the failed check names:
   `gh pr checks {pr-number} --json name,status,conclusion --jq '.[] | select(.conclusion == "failure")'`

2. List the failed workflow runs for this branch:
   `gh run list --branch {branch} --status failure --json databaseId,name,conclusion --limit 5`

3. For each failed run, get the logs (truncated to last 200 lines per run to avoid context blowup):
   `gh run view {run-id} --log --failed 2>&1 | tail -200`

Collect all failure output into a single context block for the fix subagent. If `--failed` is not supported by the installed `gh` version, fall back to `gh run view {run-id} --log 2>&1 | tail -200`.

4. **Record failure summary**: Append a one-line description of the CI failure to the `ci_failures[]` array (e.g., `"jest: 2 test suites failed"`, `"eslint: 4 lint errors in src/api/routes.ts"`, `"merge conflict with origin/main"`). Keep each entry under 100 characters. This array is written to metrics in Step 12e.2.

## 11b.4. Fix Loop

Initialize: `ci_attempt = 0`, `ci_max_retries = 3`.

While `ci_attempt < ci_max_retries`:

1. Increment `ci_attempt`.

2. Print:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CI FIX: attempt {ci_attempt}/{ci_max_retries}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

3. **Launch fix subagent** using the Agent tool:

   - **Type**: `general-purpose`
   - **Prompt**:
     ```
     You are fixing CI failures (or merge conflicts) on an open pull request.
     Do NOT create a new PR or branch. Fix the code on the current branch and push.

     Task: {task-id} — {task title}
     Branch: {branch}
     PR: #{pr-number}

     Failure context:
     {If merge conflict: "Merging origin/main produced conflicts. Run `git merge origin/main`, resolve all conflicts, then commit and push."}
     {If CI failure: collected failure logs from 11b.3}

     PR diff (for context):
     {output of gh pr diff {pr-number}}

     Instructions:
     1. Analyze the failure logs (or conflict markers) to identify the root cause
     2. Read the relevant source files
     3. Fix the failing code, tests, or merge conflicts
     4. Run the project's local validation commands to confirm the fix
     5. Commit with message: "fix: {brief description}"
     6. Push to the branch: git push
     ```

4. After the subagent completes, **loop back to 11b.1** — update from main again (main may have moved while the fix was in progress), then re-wait for CI in 11b.2.

5. **All checks pass:** Break the loop. Print:
   ```
   ✓ CI checks passed (after {ci_attempt} fix attempt(s))
   ```
   Proceed to Step 12.

6. **Checks still failing:** Collect new failure logs (repeat 11b.3) and continue the loop.

## 11b.5. Max Retries Exhausted

If `ci_attempt >= ci_max_retries` and checks are still failing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CI GATE FAILED: {task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{ci_max_retries} fix attempts exhausted.
Failing checks:
  {list of still-failing check names}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**When merge-mode is OFF (standalone):**
**Pause point:** "CI checks are still failing after {ci_max_retries} fix attempts. The PR is open at {pr-url}. Would you like to: (1) Try fixing manually, (2) Close the PR and clean up?"

If the user chooses (2), run PR Failure Cleanup (Step 11).

**When merge-mode is ON:**
Print:
```
⚠️ CI gate exhausted — task {task-id} reset for retry
```
Trigger PR Failure Cleanup (Step 11) and stop — do NOT proceed to Step 12. The dev-loop's Phase 3a-retry failure recovery will handle re-queuing the task.
