ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="ukewea https://github.com/ukewea"
LABEL org.opencontainers.image.source="https://github.com/ukewea/python-talib"

ENV APT_PKG_TEMPORARY="build-essential autoconf automake autotools-dev cmake python3-dev python3-venv libtool libopenblas-dev wget"
ENV APT_PKG="python3 python3-pip liblapack3"
ENV DEBIAN_FRONTEND=noninteractive

# Make TALIB_VERSION available as an environment variable
ARG TALIB_VERSION=0.6.4
ENV TALIB_VERSION=${TALIB_VERSION}

ENV TA_LIB_URL_TEMPLATE="https://github.com/TA-Lib/ta-lib/releases/download/v${TALIB_VERSION}/ta-lib_${TALIB_VERSION}_\$ARCH.deb"

COPY ta-lib ./ta-lib

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
  if [ -n "$final_arch" ]; then \
    echo "Detected $arch, using TA-Lib $TALIB_VERSION .deb" && \
    TALIB_URL="$(echo "$TA_LIB_URL_TEMPLATE" | sed "s/\$ARCH/$final_arch/g")" && \
    wget -O /tmp/ta-lib.deb "$TALIB_URL" && \
    dpkg -i /tmp/ta-lib.deb; \
  else \
    echo "Arch $arch not supported by pre-compiled TA-Lib .deb. Falling back to 0.4.0 local source." && \
    cd ta-lib && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    ln -s /usr/lib/libta_lib.so /usr/lib/libta-lib.so && \
    ln -s /usr/lib/libta_lib.a /usr/lib/libta-lib.a && \
    ln -s /usr/lib/libta_lib.la /usr/lib/libta-lib.la && \
    ldconfig && \
    cd ..; \
  fi && \
  \
  # Create a Python virtual environment for TA-Lib
  # this change is to cater the limitation that Python 3.11+ don't allow pip to install packages system-wide by default
  python3 -m venv /venv && \
  /venv/bin/python -m pip install --upgrade pip && \
  /venv/bin/pip install --no-cache-dir numpy TA-Lib pandas && \
  \
  # Clean up
  rm -rf ta-lib /tmp/ta-lib.deb && \
  apt-get autoremove -y ${APT_PKG_TEMPORARY} && \
  rm -rf /var/lib/apt/lists/*
