ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="ukewea https://github.com/ukewea"
LABEL org.opencontainers.image.source="https://github.com/ukewea/python-talib"

ENV APT_PKG_TEMPORARY="build-essential autoconf automake autotools-dev cmake python3-dev python3-venv libtool-bin libopenblas-dev wget"
ENV APT_PKG="python3 python3-pip liblapack3"
ENV DEBIAN_FRONTEND=noninteractive

# TA-Lib C library version (paired with pip TA-Lib>=0.7.1 below). Override only to experiment/rollback.
ARG TALIB_C_VERSION="0.7.1"

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
  talib_c="${TALIB_C_VERSION}" && \
  py_mm="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')" && \
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
  # Pair Python package with C library 0.7.x on all lines (py312/313/314).
  # Historical note: 0.6.5 pip failed on some armhf builds; 0.7.x works on py314 incl. armv7 — re-try all arches.
  pip install --no-cache-dir 'TA-Lib>=0.7.1' pandas && \
  \
  # Clean up
  apt-get autoremove -y ${APT_PKG_TEMPORARY} && \
  rm -rf /var/lib/apt/lists/*
