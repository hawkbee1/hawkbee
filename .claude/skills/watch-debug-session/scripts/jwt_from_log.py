#!/usr/bin/env python3
"""Decodes the last JWT logged under a key, even when logcat truncated it.

Usage: jwt_from_log.py <log file> [key]

`key` is the JSON field or header name the JWT was logged under, such as
`jwt` or `Authorization`. Without it, the
last `eyJ...` token in the log is used.

Logcat cuts each line at about 4 KB, so long JWTs are usually incomplete. This
prints whatever survives: the header, the payload if present, and for each
`x5c` certificate either its subject and issuer (via openssl) when it is
complete, or the readable strings of the partial DER, which normally still
include the issuer and subject names.
"""

import base64
import json
import re
import subprocess
import sys
import tempfile


def b64url_prefix(segment: str, complete: bool = False) -> bytes:
    """Decodes a base64url segment: padded when [complete], otherwise as much
    of it as forms whole 4-char groups."""
    if complete:
        return base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4))
    return base64.urlsafe_b64decode(segment[: len(segment) // 4 * 4])


def describe_certificate(b64: str, complete: bool) -> str:
    der = base64.b64decode(b64[: len(b64) // 4 * 4] if not complete else b64)
    with tempfile.NamedTemporaryFile(suffix=".der") as handle:
        handle.write(der)
        handle.flush()
        if complete:
            result = subprocess.run(
                ["openssl", "x509", "-inform", "DER", "-in", handle.name,
                 "-noout", "-subject", "-issuer", "-dates"],
                capture_output=True, text=True,
            )
            if result.returncode == 0:
                return result.stdout.strip()
        strings = re.findall(rb"[ -~]{4,}", der)
        return "partial certificate, readable strings: " + " | ".join(
            s.decode() for s in strings[:12]
        )


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    key = sys.argv[2] if len(sys.argv) > 2 else None

    pattern = (
        # A JSON field (`"key":"eyJ…"`) or a logged header (`Header key: eyJ…`).
        rf'"?{re.escape(key)}"?\s*:\s*"?(eyJ[A-Za-z0-9_\-.]+)'
        if key
        else r"(eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-.]*)"
    )
    tokens = re.findall(pattern, text)
    if not tokens:
        sys.exit(f"no JWT found{' under ' + key if key else ''}")
    token = tokens[-1]
    segments = token.split(".")
    print(f"token length in log: {len(token)} chars, "
          f"{len(segments)} segment(s) visible")

    header_text = b64url_prefix(segments[0], complete=len(segments) > 1).decode(
        "latin1"
    )
    try:
        header = json.loads(header_text)
        print("header:", json.dumps({k: v for k, v in header.items()
                                     if k != "x5c"}))
        chain = [(c, True) for c in header.get("x5c", [])]
    except json.JSONDecodeError:
        print("header (truncated):", header_text[:200])
        match = re.search(r'"x5c":\["(.*)', header_text)
        chain = []
        if match:
            parts = match.group(1).split('","')
            chain = [(p, True) for p in parts[:-1]]
            chain.append((parts[-1].split('"')[0], False))

    for index, (certificate, complete) in enumerate(chain):
        print(f"x5c[{index}]:", describe_certificate(certificate, complete))

    if len(segments) > 1 and segments[1]:
        payload = b64url_prefix(segments[1], complete=len(segments) > 2).decode(
            "latin1"
        )
        print("payload" + ("" if len(segments) > 2 else " (maybe truncated)")
              + ":", payload[:600])


if __name__ == "__main__":
    main()
