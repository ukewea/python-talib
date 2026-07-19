ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="ukewea https://github.com/ukewea"
LABEL org.opencontainers.image.source="https://github.com/ukewea/python-talib"

ENV APT_PKG_TEMPORARY="build-essential autoconf automake autotools-dev cmake python3-dev python3-venv libtool-bin libopenblas-dev wget"
ENV APT_PKG="python3 python3-pip liblapack3"
ENV DEBIAN_FRONTEND=noninteractive

# Optional override: if empty, selected from Python version inside RUN.
# Python >= 3.14 → C 0.7.1 + pip TA-Lib>=0.7.1; older → C 0.6.4 + pip 0.6.x
ARG TALIB_C_VERSION=""

RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y ${APT_PKG_TEMPORARY} ${APT_PKG} && \
  ln -s /usr/include/locale.h /usr/include/xlocale.h && \
  \
  arch="$(dpkg --print-architecture)" && \
  case "$arch" in \
    amd64|x86_64) final_arch="amd64" ;; \
    arm64|aarch64) final_arch="arm64" ;; \
    *) final_arch="" ;; \
  esac && \
  \
  py_mm="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')" && \
  if [ -n "${TALIB_C_VERSION}" ]; then \
    talib_c="${TALIB_C_VERSION}"; \
  elif python3 -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 14) else 1)"; then \
    talib_c="0.7.1"; \
  else \
    talib_c="0.6.4"; \
  fi && \
  echo "Python ${py_mm}; installing TA-Lib C ${talib_c}" && \
  \
  if [ -n "$final_arch" ]; then \
    echo "Detected $arch, using TA-Lib C ${talib_c} .deb" && \
    TALIB_URL="https://github.com/TA-Lib/ta-lib/releases/download/v${talib_c}/ta-lib_${talib_c}_${final_arch}.deb" && \
    wget -O /tmp/ta-lib.deb "$TALIB_URL" && \
    dpkg -i /tmp/ta-lib.deb && \
    rm -rf /tmp/ta-lib.deb; \
  else \
    echo "Arch $arch not supported by pre-compiled .deb, building TA-Lib C ${talib_c} from source." && \
    wget -O /tmp/ta-lib-src.tgz "https://github.com/TA-Lib/ta-lib/releases/download/v${talib_c}/ta-lib-${talib_c}-src.tar.gz" && \
    mkdir /tmp/ta-lib && \
    tar xf /tmp/ta-lib-src.tgz -C /tmp/ta-lib --strip-components=1 && \
    cd /tmp/ta-lib && \
    ./configure --prefix=/usr && \
    ( make -j4 || : ) && \
    make -j4 && \
    make install && \
    libtool --finish /usr/lib && \
    cd / && \
    rm -rf /tmp/ta-lib /tmp/ta-lib-src.tgz; \
  fi && \
  \
  # Create a Python virtual environment for TA-Lib
  # this change is to cater the limitation that Python 3.11+ don't allow pip to install packages system-wide by default
  python3 -m venv /venv && \
  . /venv/bin/activate && \
  pip install --no-cache-dir --upgrade pip cython && \
  # Python TA-Lib package pins (paired with C version above):
  # - 3.14+: C 0.7.1 + pip TA-Lib>=0.7.1 (0.6.x fails Cython build on 3.14; match C/Python 0.7.x)
  # - deb arches (amd64/arm64): TA-Lib==0.6.5 on older Python
  # - source path (e.g. armhf): TA-Lib==0.6.4 on older Python (0.6.5 failed there historically)
  if python3 -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 14) else 1)"; then \
    pip install --no-cache-dir 'TA-Lib>=0.7.1' pandas; \
  elif [ -n "$final_arch" ]; then \
    pip install --no-cache-dir TA-Lib==0.6.5 pandas; \
  else \
    pip install --no-cache-dir TA-Lib==0.6.4 pandas; \
  fi && \
  \
  # Clean up
  apt-get autoremove -y ${APT_PKG_TEMPORARY} && \
  rm -rf /var/lib/apt/lists/*
