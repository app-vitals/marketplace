# Meeting Transcripts

Browse and read meeting transcripts captured by the [mt](https://github.com/app-vitals/mt) CLI tool.

## Prerequisites

- `mt` CLI installed and configured with recordings available

## Installation

```
/plugin install meeting-transcripts@app-vitals/marketplace
```

## Commands

### `/transcripts [time-ref or "list"]`

List recent transcripts or read a specific one by time reference.

```
/transcripts              — List recent transcripts
/transcripts list         — List recent transcripts
/transcripts 9am          — Read the transcript closest to 9am today
/transcripts yesterday    — List transcripts from yesterday
```

The command uses `mt list` under the hood to find transcripts by local time, then reads and summarizes the matching file. If multiple transcripts match your query, you'll be asked to pick one.

After reading a transcript, Claude can help with follow-ups — summarize, extract action items, draft a response, etc.
