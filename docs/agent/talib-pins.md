# TA-Lib version pins

Source of truth: `Dockerfile`. This page explains **policy**, not a frozen version table.

## Policy (read `Dockerfile` for exact numbers)

| Python (in image) | TA-Lib **C** library | Python package (`pip`) |
|-------------------|----------------------|-------------------------|
| **&lt; 3.14** | `0.6.4` (deb or source) | deb arches: `0.6.5`; source/armhf path: `0.6.4` |
| **≥ 3.14** | **`0.7.1`** (deb or source) | **`TA-Lib>=0.7.1`** (paired with C 0.7.x) |

Optional build-arg `TALIB_C_VERSION` overrides the C version if set non-empty.

Do **not** treat C and pip versions as one number. Function API for classic indicators is stable; 0.7.x adds/documents ACCBANDS / AVGDEV / IMI more completely.

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

1. Edit selection logic / pins in `Dockerfile` (C version by Python major.minor + pip pins).
2. Confirm `.deb` + source tarball exist on GitHub releases for the C version (amd64/arm64 debs).
3. Rebuild; CI smoke must pass (ACCBANDS / AVGDEV / IMI required for all lines).
4. Do not paste version tables into root `AGENTS.md`.
