#!/usr/bin/env bash
# Run full smoke (incl. ACCBANDS/AVGDEV/IMI) against a python-talib image.
# Uses stdin so it works with remote DOCKER_HOST (no host volume mount).
#
# Usage:
#   ./scripts/verify_talib_accbands_avgdev_imi.sh <image> [expected_python]
#   ./scripts/verify_talib_accbands_avgdev_imi.sh python-talib:py314 3.14
set -euo pipefail

IMAGE="${1:?usage: $0 <docker-image> [expected_python]}"
EXPECTED_PYTHON="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${EXPECTED_PYTHON}" ]; then
  # Discover from image when not provided
  EXPECTED_PYTHON="$(docker run --rm "${IMAGE}" /venv/bin/python -c \
    'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
fi

docker run --rm -i -e EXPECTED_PYTHON="${EXPECTED_PYTHON}" "${IMAGE}" \
  /venv/bin/python - < "${SCRIPT_DIR}/smoke_test.py"
