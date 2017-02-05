FROM resin/armv7hf-debian-qemu
MAINTAINER Benoit Louy <benoit.louy@fastmail.com>

RUN [ "cross-build-start" ]

RUN apt-get update && apt-get install -y \
        autoconf \
        build-essential \
        imagemagick \
        libbz2-dev \
        libcurl4-openssl-dev \
        libevent-dev \
        libffi-dev \
        libglib2.0-dev \
        libjpeg-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        libmysqlclient-dev \
        libncurses-dev \
        libpq-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# install dbus-python dependencies 
RUN apt-get update && apt-get install -y --no-install-recommends \
        libdbus-1-dev \
        libdbus-glib-1-dev \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -y autoremove

# key 63C7CC90: public key "Simon McVittie <smcv@pseudorandom.co.uk>" imported
# key 3372DCFA: public key "Donald Stufft (dstufft) <donald@stufft.io>" imported
RUN gpg --keyserver keyring.debian.org --recv-keys 4DE8FF2A63C7CC90 \
    && gpg --keyserver pgp.mit.edu  --recv-key 6E3CBCE93372DCFA \
    && gpg --keyserver pgp.mit.edu --recv-keys 0x52a43a1e4b77b059

ENV PYTHON_VERSION 3.5.2

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 9.0.1
ENV PYTHON_PIP_SHA256 d03fabbc4fbf2fbfc2f97307960aef2b3ca4c880ecda993dcc35957e33d7cd76

ENV SETUPTOOLS_SHA256 197b0c1e69a29c3a9eab446ef0a1884890da0c9784b8f556d0c64071819991d6
ENV SETUPTOOLS_VERSION 28.6.1

RUN set -x \
    && curl -SLO "http://resin-packages.s3.amazonaws.com/python/v$PYTHON_VERSION/Python-$PYTHON_VERSION.linux-armv7hf.tar.gz" \
    && echo "31ccb530df0d099522c41e7a67b43b56b1ea78f844f32cba86b72f9d24636054  Python-3.5.2.linux-armv7hf.tar.gz" | sha256sum -c - \
    && tar -xzf "Python-$PYTHON_VERSION.linux-armv7hf.tar.gz" --strip-components=1 \
    && rm -rf "Python-$PYTHON_VERSION.linux-armv7hf.tar.gz" \
    && ldconfig \
    && mkdir -p /usr/src/python/setuptools \
    && curl -SLO https://github.com/pypa/setuptools/archive/v$SETUPTOOLS_VERSION.tar.gz \
    && echo "$SETUPTOOLS_SHA256  v$SETUPTOOLS_VERSION.tar.gz" > v$SETUPTOOLS_VERSION.tar.gz.sha256sum \
    && sha256sum -c v$SETUPTOOLS_VERSION.tar.gz.sha256sum \
    && tar -xzC /usr/src/python/setuptools --strip-components=1 -f v$SETUPTOOLS_VERSION.tar.gz \
    && rm -rf v$SETUPTOOLS_VERSION.tar.gz* \
    && cd /usr/src/python/setuptools \
    && python3 bootstrap.py \
    && python3 easy_install.py . \
    && mkdir -p /usr/src/python/pip \
    && curl -SL "https://github.com/pypa/pip/archive/$PYTHON_PIP_VERSION.tar.gz" -o pip.tar.gz \
    && echo "$PYTHON_PIP_SHA256  pip.tar.gz" > pip.tar.gz.sha256sum \
    && sha256sum -c pip.tar.gz.sha256sum \
    && tar -xzC /usr/src/python/pip --strip-components=1 -f pip.tar.gz \
    && rm pip.tar.gz* \
    && cd /usr/src/python/pip \
    && python3 setup.py install \
    && cd .. \
    && find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && cd / \
    && rm -rf /usr/src/python ~/.cache

# install "virtualenv", since the vast majority of users of this image will want it
RUN pip3 install --no-cache-dir virtualenv

ENV PYTHON_DBUS_VERSION 1.2.4

# install dbus-python
RUN set -x \
    && mkdir -p /usr/src/dbus-python \
    && curl -SL "http://dbus.freedesktop.org/releases/dbus-python/dbus-python-$PYTHON_DBUS_VERSION.tar.gz" -o dbus-python.tar.gz \
    && curl -SL "http://dbus.freedesktop.org/releases/dbus-python/dbus-python-$PYTHON_DBUS_VERSION.tar.gz.asc" -o dbus-python.tar.gz.asc \
    && gpg --verify dbus-python.tar.gz.asc \
    && tar -xzC /usr/src/dbus-python --strip-components=1 -f dbus-python.tar.gz \
    && rm dbus-python.tar.gz* \
    && cd /usr/src/dbus-python \
    && PYTHON=python3.5 ./configure \
    && make -j$(nproc) \
    && make install -j$(nproc) \
    && cd / \
    && rm -rf /usr/src/dbus-python

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
    && ln -sf pip3 pip \
    && ln -sf easy_install-3.5 easy_install \
    && ln -sf idle3 idle \
    && ln -sf pydoc3 pydoc \
    && ln -sf python3 python \
    && ln -sf python3-config python-config

RUN [ "cross-build-end" ]

ENV PYTHONPATH /usr/lib/python3/dist-packages:$PYTHONPATH
