#!/usr/bin/env python3
"""
Back-compat entry for ACCBANDS / AVGDEV / IMI checks.

Prefer scripts/smoke_test.py (full CI contract). This sets EXPECTED_PYTHON from
the running interpreter when unset, then runs the smoke suite.
"""

from __future__ import annotations

import os
import runpy
import sys


def main() -> int:
    if not os.environ.get("EXPECTED_PYTHON", "").strip():
        os.environ["EXPECTED_PYTHON"] = (
            f"{sys.version_info.major}.{sys.version_info.minor}"
        )

    script_dir = os.path.dirname(os.path.abspath(__file__))
    smoke_path = os.path.join(script_dir, "smoke_test.py")
    if not os.path.isfile(smoke_path):
        print(f"FAIL: missing {smoke_path}", file=sys.stderr)
        return 2

    try:
        runpy.run_path(smoke_path, run_name="__main__")
    except SystemExit as e:
        code = e.code
        if code is None:
            return 0
        if isinstance(code, int):
            return code
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
