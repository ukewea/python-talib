ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="ukewea https://github.com/ukewea"
LABEL org.opencontainers.image.source="https://github.com/ukewea/python-talib"

ENV APT_PKG_TEMPORARY="build-essential autoconf automake autotools-dev cmake python3-dev python3-venv libtool-bin libopenblas-dev wget"
ENV APT_PKG="python3 python3-pip liblapack3"
ENV DEBIAN_FRONTEND=noninteractive

ARG TALIB_C_VERSION="0.6.4"
ARG TALIB_PY_MAJOR_MIN_VERSION="0.6"

ENV TALIB_C_VERSION=${TALIB_C_VERSION}
ENV TALIB_PY_MAJOR_MIN_VERSION=${TALIB_PY_MAJOR_MIN_VERSION}

ENV TA_LIB_C_DEB_URL_TEMPLATE="https://github.com/TA-Lib/ta-lib/releases/download/v${TALIB_C_VERSION}/ta-lib_${TALIB_C_VERSION}_\$ARCH.deb"
ENV TA_LIB_C_SRC_URL="https://github.com/TA-Lib/ta-lib/releases/download/v${TALIB_C_VERSION}/ta-lib-${TALIB_C_VERSION}-src.tar.gz"

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
    echo "Detected $arch, using TA-Lib $TALIB_C_VERSION .deb" && \
    TALIB_URL="$(echo "$TA_LIB_C_DEB_URL_TEMPLATE" | sed "s/\$ARCH/$final_arch/g")" && \
    wget -O /tmp/ta-lib.deb "$TALIB_URL" && \
    dpkg -i /tmp/ta-lib.deb; \
    rm -rf /tmp/ta-lib.deb; \
  else \
    echo "Arch $arch not supported by pre-compiled .deb, building TA-Lib $TALIB_C_VERSION from source." && \
    wget -O /tmp/ta-lib-src.tgz "${TA_LIB_C_SRC_URL}" && \
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
  pip install --no-cache-dir TA-Lib~=${TALIB_PY_MAJOR_MIN_VERSION} pandas && \
  \
  # Clean up  
  apt-get autoremove -y ${APT_PKG_TEMPORARY} && \
  rm -rf /var/lib/apt/lists/*
