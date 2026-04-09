#!/usr/bin/env python3
"""Convert a self-contained HTML discovery report to PDF using Playwright.

Why Playwright? Off-the-shelf HTML→PDF tools (wkhtmltopdf, weasyprint, browser
print dialogs driven by headless tools) routinely drop modern CSS features like
CSS grid, flexbox edge cases, web fonts, and CSS variables. Playwright drives a
real headless Chromium, so the PDF matches what the report looks like in a
browser — no layout drift, no missing components.

Usage:
    uv run --with playwright python html-to-pdf.py <input.html> <output.pdf>

First-time setup (one-time chromium download, ~200MB):
    uv run --with playwright playwright install chromium

The script exits with a friendly message if chromium is missing and tells you
exactly which command to run.
"""

from __future__ import annotations

import sys
from pathlib import Path


def convert(input_html: Path, output_pdf: Path) -> None:
    """Render an HTML file to PDF via headless chromium."""
    # Deferred import so the --help / usage path works even when playwright
    # isn't installed yet (e.g. if the user forgets the --with flag).
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        sys.exit(
            "Error: playwright is not installed.\n"
            "Run with uv:\n"
            "  uv run --with playwright python html-to-pdf.py <input.html> <output.pdf>"
        )

    output_pdf.parent.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        try:
            browser = p.chromium.launch()
        except Exception as e:
            message = str(e)
            if "Executable doesn't exist" in message or "playwright install" in message:
                sys.exit(
                    "Error: chromium is not installed for playwright.\n"
                    "Run this one-time setup command:\n"
                    "  uv run --with playwright playwright install chromium\n"
                    "Then re-run this script."
                )
            raise

        try:
            page = browser.new_page()
            # file:// URI requires an absolute path
            page.goto(f"file://{input_html.resolve()}")
            # Wait for any late-loading resources (fonts, images) to settle
            page.wait_for_load_state("networkidle")
            page.pdf(
                path=str(output_pdf),
                format="A4",
                print_background=True,
                margin={
                    "top": "0.5in",
                    "right": "0.5in",
                    "bottom": "0.5in",
                    "left": "0.5in",
                },
                prefer_css_page_size=False,
            )
        finally:
            browser.close()


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(
            "Usage: html-to-pdf.py <input.html> <output.pdf>\n"
            "Typical invocation:\n"
            "  uv run --with playwright python html-to-pdf.py report.html report.pdf"
        )

    input_html = Path(sys.argv[1])
    output_pdf = Path(sys.argv[2])

    if not input_html.exists():
        sys.exit(f"Error: input file not found: {input_html}")

    if input_html.suffix.lower() not in {".html", ".htm"}:
        sys.exit(f"Error: input must be an HTML file, got: {input_html.suffix}")

    convert(input_html, output_pdf)

    size_bytes = output_pdf.stat().st_size
    print(f"PDF written: {output_pdf.resolve()}")
    print(f"Size: {size_bytes:,} bytes ({size_bytes / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
