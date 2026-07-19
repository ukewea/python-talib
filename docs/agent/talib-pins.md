# TA-Lib version pins

Source of truth: `Dockerfile`. This page explains **policy**, not a frozen version table.

## Policy (read `Dockerfile` for exact numbers)

| Component | Policy |
|-----------|--------|
| TA-Lib **C** library | Default `ARG TALIB_C_VERSION` (currently **0.7.1**); deb on amd64/arm64, source otherwise (e.g. armhf) |
| Python package (`pip`) | **`TA-Lib>=0.7.1`** on **all** Python lines (paired with C 0.7.x) |
| pandas | unpinned minor (same `pip install` line) |

Optional build-arg `TALIB_C_VERSION` overrides the C version (e.g. rollback experiments). Keep C and pip on the same major.minor family.

Do **not** treat C-library and Python-package versions as one number, but do keep them paired (0.7.x + 0.7.x). Function API for classic indicators is stable; 0.7.x documents ACCBANDS / AVGDEV / IMI more completely.

## Smoke (includes ACCBANDS / AVGDEV / IMI)

CI runs `scripts/smoke_test.py` after every single-arch build (`build-image.yaml`).
That script is the smoke contract: Python version, SMA, and ACCBANDS / AVGDEV / IMI.

```bash
# Same as CI (stdin — works with remote DOCKER_HOST)
docker run --rm -i -e EXPECTED_PYTHON=<from YAML> <image> \
  /venv/bin/python - < scripts/smoke_test.py

# Convenience wrapper (discovers Python major.minor from the image if omitted)
./scripts/verify_talib_accbands_avgdev_imi.sh <image> [expected_python]
```

## Updating TA-Lib

1. Bump `TALIB_C_VERSION` and the `pip install 'TA-Lib>=…'` floor in `Dockerfile` together.
2. Confirm `.deb` (amd64/arm64) + source tarball exist on GitHub releases for that C version.
3. Rebuild all Python lines; CI smoke must pass (ACCBANDS / AVGDEV / IMI).
4. Watch armhf/source path especially (historically flaky on some 0.6.x bumps).
5. Do not paste version tables into root `AGENTS.md`.
