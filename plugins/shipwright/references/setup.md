# Shipwright Setup — Cron Configuration

Shipwright relies on two agent crons. Add these entries to your agent's `crons.json` after installing the plugin.

## Execution Cron

Picks up the next `pending` Shipwright task and builds it autonomously.

```json
{
  "id": "shipwright-dev-task",
  "schedule": "0 * * * *",
  "prompt": "Run /shipwright:dev-task — pick the next ready task from state/todos.json and execute it autonomously. If no tasks are ready (all pending tasks have unmet dependencies, or the queue is empty), stay silent.",
  "user": "{YOUR_SLACK_USER_ID}",
  "enabled": true
}
```

## Review Cron

Reviews all open PRs with `status: pr_open` in `state/todos.json`.

```json
{
  "id": "shipwright-review",
  "schedule": "30 * * * *",
  "prompt": "Run /shipwright:review — review all open Shipwright PRs (status: pr_open in state/todos.json). If no PRs are open, stay silent.",
  "user": "{YOUR_SLACK_USER_ID}",
  "enabled": true
}
```

## Notes

- **Schedule**: Both crons default to hourly, offset by 30 minutes so execution and review don't overlap. Adjust to match your team's cadence.
- **Slack trigger**: Either cron can also be triggered manually by messaging your agent. The same prompt works for both.
- **Parallelism**: Multiple agents can run `dev-task` simultaneously — each picks a different `pending` task. Status is written to `todos.json` immediately on pickup (`in_progress`), preventing double-claiming.
- **Review scope**: The review cron only covers Shipwright tasks. If your agent reviews all open PRs on a separate cadence, that's a distinct cron and not part of this plugin.
