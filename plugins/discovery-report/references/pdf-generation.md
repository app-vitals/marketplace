# PDF Generation

Convert a generated HTML discovery report into a PDF using headless Chromium
via Playwright.

## Why Playwright

Off-the-shelf HTML→PDF tools routinely fail on modern CSS:

- **wkhtmltopdf** — unmaintained, chokes on CSS grid and CSS variables
- **weasyprint** — missing flexbox support for many layouts, no JS execution
- **`prince` / `pandoc --pdf-engine=...`** — expensive or drops custom fonts

Playwright drives a real headless Chromium. The PDF matches exactly what the
report looks like in a browser. Every component in `html-template.md` (stat
cards, before/after grids, timelines, callouts) renders correctly.

## Prerequisites

- **Python 3.10+** (check with `python3 --version`)
- **uv** (check with `uv --version`). If missing, install via:
  `curl -LsSf https://astral.sh/uv/install.sh | sh`

That's it. No global `pip install`, no virtualenv — `uv run --with` handles the
dependency ephemerally.

## First-time chromium setup

Playwright needs a chromium binary. This is a one-time download of roughly
200 MB, cached under `~/.cache/ms-playwright/`:

```bash
uv run --with playwright playwright install chromium
```

If this step is skipped, the script below will fail with a friendly message
telling you to run exactly this command.

## Converting a report

From anywhere, given an input HTML and desired output PDF path:

```bash
uv run --with playwright python "${CLAUDE_PLUGIN_ROOT}/scripts/html-to-pdf.py" \
  <input.html> <output.pdf>
```

### Concrete example

```bash
uv run --with playwright python \
  "${CLAUDE_PLUGIN_ROOT}/scripts/html-to-pdf.py" \
  /tmp/checkout-504-incident-discovery-report.html \
  /tmp/checkout-504-incident-discovery-report.pdf
```

The script will:

1. Resolve the input path (absolute `file://` URI)
2. Launch headless chromium
3. Navigate to the HTML file and wait for network-idle
4. Render to A4 with print backgrounds and 0.5in margins
5. Print the output path and size

## Defaults

The script uses these PDF options — intentionally not configurable to keep the
skill simple. Edit the script if you need different values:

| Option | Value | Why |
|--------|-------|-----|
| `format` | `A4` | Safe international default; letter also works but A4 fits code blocks better |
| `print_background` | `True` | Required — the dark theme is background colors, not text colors |
| `margin` | 0.5in all sides | Enough whitespace for binding without wasting space |
| `prefer_css_page_size` | `False` | Forces A4 regardless of any future `@page` rules in HTML |

## Troubleshooting

### "Executable doesn't exist" / "playwright install"

You skipped the chromium install. Run:

```bash
uv run --with playwright playwright install chromium
```

### PDF is all white or missing backgrounds

The `print_background=True` flag should prevent this. If you see it anyway, the
script may have been modified. Revert the `page.pdf(...)` call to include
`print_background=True`.

### Colors look wrong

Chromium renders the dark theme perfectly, but some PDF viewers force a "light
mode" remap. Open the PDF in a neutral viewer (Preview.app on macOS, Acrobat,
browsers). Do not view with viewers that auto-invert colors.

### Fonts look different from the HTML

The report uses system fonts (`-apple-system`, `BlinkMacSystemFont`) and a
monospace fallback chain. The PDF substitutes whatever chromium has available.
On macOS this usually matches exactly. On Linux, install the Apple system fonts
or tolerate Roboto as a fallback — the layout is identical.

## Credential safety

The script does not transmit, log, or write anything beyond the requested PDF
path. The HTML input must already be safe (per SKILL.md hard rules — no
credentials in the HTML). The conversion step adds no new risk.
