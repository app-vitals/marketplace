---
name: transcripts
description: Browse and read meeting transcripts
argument-hint: "[time reference or 'list']"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# /transcripts - Browse and Read Meeting Transcripts

Access meeting transcripts captured by the `mt` CLI tool.

## Usage

```
/transcripts              — List recent transcripts
/transcripts list         — List recent transcripts
/transcripts 9am          — Read the transcript closest to 9am today
/transcripts yesterday    — List transcripts from yesterday
```

## Process

1. **Always start by running `mt list`** to get available transcripts with local times and file paths.

2. **If the user specified a time reference** (e.g., "9am", "this morning", "yesterday afternoon"):
   - Match against the local times shown in `mt list` output
   - NEVER try to construct the file path manually from a time reference. Always use the path from `mt list`.
   - Read the matching transcript file using the Read tool
   - Present a brief summary of what was discussed

3. **If no time reference or "list"**:
   - Show the `mt list` output formatted clearly
   - Ask which transcript they'd like to read

4. **If multiple transcripts could match** (e.g., "this morning" with several AM recordings):
   - Show the candidates and ask which one

## Important

- The `mt list` command shows times in **local time**. Users will reference times in local time. Match accordingly.
- Transcript filenames use UTC, but you should NEVER need to parse filenames. Always use `mt list` to get file paths.
- After reading a transcript, offer to help with follow-ups: summarize, extract action items, draft a response, etc.
