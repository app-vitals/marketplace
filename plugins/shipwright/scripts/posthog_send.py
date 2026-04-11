#!/usr/bin/env python3
"""
Shipwright PostHog event sender.

Usage:
    python3 posthog_send.py EVENT_JSON

Where EVENT_JSON is a single JSON object:
    {
        "event": "shipwright_task_started",
        "distinct_id": "shipwright/{project}/{task_id}",
        "timestamp": "2026-04-10T14:30:00Z",
        "properties": {
            "$insert_id": "shipwright_task_started/{project}/{task_id}",
            ...
        }
    }

Environment variables:
    POSTHOG_PROJECT_API_KEY  Required. If absent, exits 0 silently (no-op).
    POSTHOG_HOST             Optional. Defaults to https://us.i.posthog.com

Exit codes:
    0  Success or silently skipped (no API key)
    1  HTTP error or JSON parse error
"""

import json
import os
import ssl
import sys
import urllib.request
import urllib.error

# Known system CA bundle locations (covers macOS python.org builds, Linux, etc.)
_CA_CANDIDATES = [
    "/etc/ssl/cert.pem",           # macOS system bundle
    "/etc/ssl/certs/ca-certificates.crt",  # Debian/Ubuntu
    "/etc/pki/tls/certs/ca-bundle.crt",    # RHEL/CentOS
]


def _ssl_context():
    """Return an SSL context using an explicit CA bundle when available.

    python.org macOS builds ship without a CA bundle populated, causing
    CERTIFICATE_VERIFY_FAILED even though the system has a valid bundle at
    /etc/ssl/cert.pem. Prefer explicit CA files over the (possibly empty)
    default to keep this working without requiring 'Install Certificates.command'.
    """
    for ca in _CA_CANDIDATES:
        if os.path.exists(ca):
            return ssl.create_default_context(cafile=ca)
    return ssl.create_default_context()


def main():
    api_key = os.environ.get("POSTHOG_PROJECT_API_KEY", "")
    if not api_key:
        sys.exit(0)

    if len(sys.argv) < 2:
        print("Usage: posthog_send.py EVENT_JSON", file=sys.stderr)
        sys.exit(1)

    try:
        event = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        print(f"⚠ PostHog: invalid event JSON: {e}", file=sys.stderr)
        sys.exit(1)

    host = os.environ.get("POSTHOG_HOST", "https://us.i.posthog.com").rstrip("/")
    payload = json.dumps({"api_key": api_key, "batch": [event]}).encode()

    req = urllib.request.Request(
        f"{host}/batch/",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        urllib.request.urlopen(req, context=_ssl_context(), timeout=10)
    except urllib.error.URLError as e:
        print(
            f"⚠ PostHog export failed: {e} — event not delivered",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
