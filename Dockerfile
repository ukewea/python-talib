ARG BASE_IMAGE=ubuntu:23.10
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="ukewea https://github.com/ukewea"
LABEL org.opencontainers.image.source = "https://github.com/ukewea/python-talib"

ENV APT_PKG_TEMPORARY="build-essential autoconf automake autotools-dev cmake python3-dev python3-venv"
ENV APT_PKG="python3 python3-pip libopenblas-dev"
ENV DEBIAN_FRONTEND=noninteractive

COPY ta-lib ./ta-lib

RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y ${APT_PKG_TEMPORARY} ${APT_PKG} && \
  ln -s /usr/include/locale.h /usr/include/xlocale.h && \
  \
  # compile TA-Lib library
  cd ta-lib && \
  ./configure --prefix=/usr; \
  make && \
  make install && \
  cd .. && \
  rm -rf ta-lib && \
  \
  # Create a Python virtual environment for TA-Lib
  # this change is to cater the limitation that Python 3.11+ don't allow pip to install packages system-wide by default
  python3 -m venv /ctr-py-venv \
  && /ctr-py-venv/bin/pip install --no-cache-dir TA-Lib\
  && \
  # Clean up
  apt-get autoremove -y ${APT_PKG_TEMPORARY} && \
  rm -rf /var/lib/apt/lists/*
