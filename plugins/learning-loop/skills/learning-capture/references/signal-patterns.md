# Signal Patterns

What kinds of statements indicate learnings worth capturing.

## High Confidence (Capture readily)

### Explicit Corrections
| Pattern | Example |
|---------|---------|
| Use X instead of Y | "use uv instead of pip" |
| No, do/use X | "no, use pytest" |
| Don't do X, do Y | "don't use var, use const" |
| That's wrong/incorrect | "that's incorrect, it should be..." |

### Explicit Rules
| Pattern | Example |
|---------|---------|
| Always X | "Always run tests before committing" |
| Never X | "Never commit secrets to git" |

### Success After Struggle
| Pattern | Example |
|---------|---------|
| That worked! | "that worked!" |
| It's fixed | "it's fixed now" |
| Problem solved | "problem solved" |

## Medium Confidence (Capture with brief confirmation)

### Soft Corrections
| Pattern | Example |
|---------|---------|
| Actually, X | "actually, that should be async" |
| Prefer X over Y | "prefer const over let" |
| Better to X | "better to use early returns" |

### Discoveries
| Pattern | Example |
|---------|---------|
| Non-obvious solution | Solutions that took multiple attempts |
| Misleading errors | Error message didn't point to real cause |
| Undocumented behavior | "turns out you need to..." |

## Low Confidence (Only with explicit /learn)

| Pattern | Example |
|---------|---------|
| Have you considered | "have you considered using TypeScript?" |
| Why not X | "why not use a map instead?" |
| Observations | "FYI, this API is deprecated" |

## Skip Indicators (Don't Capture)

- "just this once"
- "for now"
- "temporarily"
- "in this case"
- "only here"

## Capture Indicators (Definitely Capture)

- "from now on"
- "going forward"
- "in general"
- "as a rule"
- "remember this"
- "save this"

## False Positives to Avoid

Don't capture:
- Questions without assertions
- Hypotheticals ("if we were to...")
- Quotes from documentation being discussed
- One-time instructions with skip indicators
