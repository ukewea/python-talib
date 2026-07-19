#!/usr/bin/env python3
"""
CI / local smoke contract for python-talib images.

Checks:
  1. Python major.minor matches EXPECTED_PYTHON (required env)
  2. pandas, talib, numpy import
  3. Classic API: SMA
  4. Newer API usability: ACCBANDS, AVGDEV, IMI

Usage (matches CI; works with remote DOCKER_HOST via stdin):
  docker run --rm -i -e EXPECTED_PYTHON=3.14 <image> /venv/bin/python - < scripts/smoke_test.py

Or inside a running container with EXPECTED_PYTHON set:
  /venv/bin/python scripts/smoke_test.py
"""

from __future__ import annotations

import os
import sys


def _finite_tail(arr, name: str, min_finite: int = 1) -> None:
    import numpy as np

    if arr is None:
        raise AssertionError(f"{name}: returned None")
    a = np.asarray(arr)
    if a.size == 0:
        raise AssertionError(f"{name}: empty output")
    finite = np.isfinite(a)
    n = int(np.count_nonzero(finite))
    if n < min_finite:
        raise AssertionError(
            f"{name}: expected some finite values, got {n} finite of {a.size}"
        )
    print(f"  OK {name}: shape={a.shape} finite={n}/{a.size} sample={a[finite][-1]!r}")


def main() -> int:
    expected = os.environ.get("EXPECTED_PYTHON", "").strip()
    if not expected:
        print("FAIL: EXPECTED_PYTHON env is required", file=sys.stderr)
        return 2

    print("Python:", sys.version)
    majmin = f"{sys.version_info.major}.{sys.version_info.minor}"
    assert majmin == expected, f"expected Python {expected}, got {majmin}"
    print(f"Python version OK: {majmin}")

    try:
        import numpy as np
        import pandas as pd  # noqa: F401
        import talib
    except ImportError as e:
        print(f"FAIL: need pandas, talib, numpy: {e}", file=sys.stderr)
        return 2

    print(f"talib: {getattr(talib, '__version__', 'unknown')}")

    # --- classic API ---
    sma = talib.SMA(np.array([1.0, 2.0, 3.0], dtype=float), timeperiod=2)
    assert sma is not None, "SMA returned None"
    print("OK: SMA")

    # --- ACCBANDS / AVGDEV / IMI (usable on C 0.6.2+ / wrappers that expose them) ---
    rng = np.random.default_rng(42)
    n = 200
    close = 100.0 + np.cumsum(rng.normal(0, 0.5, size=n))
    high = close + rng.uniform(0.1, 1.5, size=n)
    low = close - rng.uniform(0.1, 1.5, size=n)

    errors: list[str] = []

    for name in ("ACCBANDS", "AVGDEV", "IMI"):
        if not hasattr(talib, name):
            errors.append(f"missing talib.{name}")
            print(f"FAIL: talib has no attribute {name}")
        else:
            print(f"OK: talib.{name} exists")

    try:
        groups = talib.get_function_groups()
        flat = {fn for fns in groups.values() for fn in fns}
        for name in ("ACCBANDS", "AVGDEV", "IMI"):
            if name in flat:
                print(f"OK: {name} listed in get_function_groups()")
            else:
                print(f"WARN: {name} not in get_function_groups() (may still be callable)")
    except Exception as e:
        print(f"WARN: get_function_groups() unavailable: {e}")

    try:
        avgdev = talib.AVGDEV(close, timeperiod=14)
        _finite_tail(avgdev, "AVGDEV")
    except Exception as e:
        errors.append(f"AVGDEV: {e}")
        print(f"FAIL AVGDEV: {e}")

    try:
        upper, middle, lower = talib.ACCBANDS(high, low, close, timeperiod=20)
        _finite_tail(upper, "ACCBANDS.upper")
        _finite_tail(middle, "ACCBANDS.middle")
        _finite_tail(lower, "ACCBANDS.lower")
        m = np.isfinite(upper) & np.isfinite(middle) & np.isfinite(lower)
        if np.any(m) and not np.all(upper[m] >= lower[m]):
            raise AssertionError("ACCBANDS: upper < lower for some bars")
        if np.any(m):
            print("  OK ACCBANDS: upper >= lower where finite")
    except Exception as e:
        errors.append(f"ACCBANDS: {e}")
        print(f"FAIL ACCBANDS: {e}")

    try:
        imi = talib.IMI(high, low, timeperiod=14)
        _finite_tail(imi, "IMI")
    except Exception as e:
        errors.append(f"IMI: {e}")
        print(f"FAIL IMI: {e}")

    try:
        from talib import abstract

        for name in ("AVGDEV", "ACCBANDS", "IMI"):
            fn = abstract.Function(name)
            print(f"OK: abstract.Function({name!r}) -> {fn}")
    except Exception as e:
        print(f"WARN: abstract API check skipped/failed: {e}")

    if errors:
        print("\nRESULT: FAILED")
        for e in errors:
            print(f"  - {e}")
        return 1

    print("\nRESULT: PASSED — Python, SMA, ACCBANDS, AVGDEV, IMI OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as e:
        print(f"FAIL: {e}", file=sys.stderr)
        raise SystemExit(1)
