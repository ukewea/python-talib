# TA-Lib version pins

Source of truth for exact values: `Dockerfile`. This page explains **what** is pinned and **how** to bump.

## What is pinned (exact numbers: open `Dockerfile`)

| Component | Where set | amd64 / arm64 (`.deb` path) | Other arches (source path, e.g. armhf) |
|-----------|-----------|-----------------------------|----------------------------------------|
| **C library** | `ARG TALIB_C_VERSION` | same for all arches | same |
| **Python package `TA-Lib`** | hardcoded in `RUN` `pip install` | one `TA-Lib==…` pin | often a different `TA-Lib==…` pin if newer fails to build |
| **pandas** | same `pip install` line | typically unpinned minor | same |
| **numpy** | transitive | not pinned directly | same |

Do **not** treat C-library and Python-package versions as one number. **Copy current pins from `Dockerfile`**, not from this page or chat memory.

## Updating TA-Lib

1. Bump `TALIB_C_VERSION` in `Dockerfile`.
2. Confirm pre-built `.deb` URLs exist for **amd64** and **arm64** for that C version (see `TA_LIB_C_DEB_URL_TEMPLATE`).
3. Bump **both** `pip install TA-Lib==…` lines if the Python package should change (deb path and source path may differ).
4. Smoke-test at least one deb arch and the source path (arm/v7) when possible.
5. Do not add TA-Lib/Ubuntu/Python version tables to root `AGENTS.md`; leave numbers in `Dockerfile` / workflows.
