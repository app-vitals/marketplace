---
name: entropy-scan
description: >
  Scan a repository against configurable golden principles to detect code health drift.
  Produces an entropy-report.md with categorized findings.
---

# entropy-scan

Scan a repository against golden principles and produce an entropy report.

## When This Activates

- User runs `/entropy-scan`
- User asks to check code health, find drift, or audit against golden principles

## Overview

entropy-scan reads a set of golden principles (configurable YAML rules) and scans the target repository for violations. Each rule has a `detection_hint` — a natural language instruction that guides the scanning agent on what to look for, what to exclude, and what to report.

Results are written to `entropy-report.md` in the working directory, organized by category and severity.

## Configuration

Rules are loaded from (highest priority first):
1. `.claude/entropy-patrol/golden-principles.yaml` — project-local overrides
2. `<plugin-dir>/skills/entropy-scan/golden-principles.yaml` — plugin defaults

See `references/customization.md` for override details and `references/schema.md` for the rule format.
