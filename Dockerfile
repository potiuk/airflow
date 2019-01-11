#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# WARNING: THIS DOCKERFILE IS NOT INTENDED FOR PRODUCTION USE OR DEPLOYMENT.
#
# Arguments of the build
ARG PYTHON_BASE_IMAGE="python:3.6-slim"
ARG APT_DEPS_IMAGE="airflow-apt-deps"
# Default cache image does not have /cache directory - it's the same as python image
ARG MASTER_WHEEL_CACHE_IMAGE=${PYTHON_BASE_IMAGE}
ARG AIRFLOW_VERSION="2.0.0.dev0"
# Speeds up building the image - cassandra driver without CYTHON saves around 10 minutes
ARG CASS_DRIVER_NO_CYTHON="1"
# Build cassandra driver on multiple CPUs
ARG CASS_DRIVER_BUILD_CONCURRENCY="8"
# By default PIP install is run without cache to make image smaller
ARG PIP_CACHE_DIRECTIVE="--no-cache-dir"
# Additional python deps to install
ARG ADDITIONAL_PYTHON_DEPS=""
# Whether to use wheel cache during the build
ARG USE_WHEEL_CACHE="false"
# PIP version used to install dependencies
ARG PIP_VERSION="19.0.1"
############################################################################################################
# This is base image with APT dependencies needed by Airflow. It is based on a python slim image
# Parameters:
#    PYTHON_BASE_IMAGE - base python image (python:x.y-slim)
############################################################################################################
FROM ${PYTHON_BASE_IMAGE} as airflow-apt-deps

# Print RUN commands by default
SHELL ["/bin/bash", "-xc"]

ARG PYTHON_BASE_IMAGE
ARG AIRFLOW_VERSION
ENV PYTHON_BASE_IMAGE=${PYTHON_BASE_IMAGE}
ENV AIRFLOW_VERSION=$AIRFLOW_VERSION

# Print versions
RUN echo "Python version: ${PYTHON_VERSION}"
RUN echo "Base image: ${PYTHON_BASE_IMAGE}"
RUN echo "Airflow version: ${AIRFLOW_VERSION}"

# Make sure noninteractie debian install is used and language variab1les set
ENV DEBIAN_FRONTEND=noninteractive LANGUAGE=C.UTF-8 LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    LC_CTYPE=C.UTF-8 LC_MESSAGES=C.UTF-8

# Increase the value below to force renstalling of all dependencies
ENV FORCE_REINSTALL_ALL_DEPENDENCIES=1

# Install curl and gnupg2 - needed to download nodejs in next step
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
           curl gnupg2 \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install basic apt dependencies
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
           # Packages to install \
           libsasl2-dev freetds-bin build-essential \
           default-libmysqlclient-dev apt-utils curl rsync netcat locales  \
           freetds-dev libkrb5-dev libssl-dev libffi-dev libpq-dev git \
           nodejs sudo \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN adduser airflow && \
    echo "airflow ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/airflow && \
    chmod 0440 /etc/sudoers.d/airflow

############################################################################################################
# This is an image with all APT dependencies needed by CI. It is built on top of the airlfow APT image
# Parameters:
#     airflow-apt-deps - this is the base image for CI deps image.
############################################################################################################
FROM airflow-apt-deps as airflow-ci-apt-deps

SHELL ["/bin/bash", "-xc"]

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

# Note missing directories on debian-stretch https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -pv /usr/share/man/man1 \
    && mkdir -pv /usr/share/man/man7 \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
      lsb-release \
      gnupg \
      dirmngr \
      openjdk-8-jdk \
      vim \
      wget \
      tmux \
      less \
      unzip \
      ldap-utils \
      postgresql-client \
      sqlite3 \
      krb5-user \
      openssh-client \
      openssh-server \
      python-selinux \
      sasl2-bin \
    && apt-get autoremove -yqq --purge \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN export DEBIAN_FRONTEND=noninteractive \
# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
    && key='A4A9406876FCBD3C456770C88C718D3B5072E1F5' \
    && export GNUPGHOME="$(mktemp -d)" \
    && for keyserver in $(shuf -e \
			ha.pool.sks-keyservers.net \
			hkp://p80.pool.sks-keyservers.net:80 \
			keyserver.ubuntu.com \
			hkp://keyserver.ubuntu.com:80 \
			pgp.mit.edu) ; do \
		  gpg --keyserver $keyserver --recv-keys "$key" && break || true ; \
	   done \
    && gpg --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg \
	&& gpgconf --kill all \
	rm -rf "$GNUPGHOME"; \
	apt-key list > /dev/null \
    && echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7" | tee -a /etc/apt/sources.list.d/mysql.list \
    && apt-get update \
    && MYSQL_PASS="secret" \
    && debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''" \
    && debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASS" \
    && debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASS" \
    && apt-get install --no-install-recommends -y mysql-client libmysqlclient-dev \
    && apt-get autoremove -yqq --purge \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV HADOOP_DISTRO=cdh
ENV HADOOP_VERSION=2.6.0 HADOOP_HOME=/tmp/hadoop-${HADOOP_DISTRO} HIVE_HOME=/tmp/hive

RUN  mkdir -pv ${HADOOP_HOME} && \
     mkdir -pv ${HIVE_HOME}  && \
     mkdir /tmp/minicluster  && \
     mkdir -pv /user/hive/warehouse && \
     chmod -R 777 ${HIVE_HOME} && \
     chmod -R 777 /user/

# Install Hadoop
# --absolute-names is a work around to avoid this issue https://github.com/docker/hub-feedback/issues/727
RUN cd /tmp && \
    wget -q https://archive.cloudera.com/cdh5/cdh/5/hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz && \
    tar xzf hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz --absolute-names --strip-components 1 -C ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz

# Install Hive
RUN cd /tmp && \
    wget -q https://archive.cloudera.com/cdh5/cdh/5/hive-1.1.0-cdh5.11.0.tar.gz && \
    tar xzf hive-1.1.0-cdh5.11.0.tar.gz --strip-components 1 -C $HIVE_HOME && \
    rm hive-1.1.0-cdh5.11.0.tar.gz

# Install MiniCluster
RUN cd /tmp && \
    wget -q https://github.com/bolkedebruin/minicluster/releases/download/1.1/minicluster-1.1-SNAPSHOT-bin.zip && \
    unzip minicluster-1.1-SNAPSHOT-bin.zip -d /tmp && \
    rm minicluster-1.1-SNAPSHOT-bin.zip

ENV PATH "$PATH:/tmp/hive/bin:$ADDITIONAL_PATH"

############################################################################################################
# This is the previous cache image in case we specify it with MASTER_WHEEL_CACHE_IMAGE argument
# The default image has no cache so we create an empty /cache
# But in CI environment and in local builds we will always try to use
# previously build wheel cache whenever available
############################################################################################################

FROM ${MASTER_WHEEL_CACHE_IMAGE} as wheel-cache-master
RUN mkdir -pv /cache
RUN find /cache

############################################################################################################
# This is a cache image that is used to provide compiled wheel packages to CI image.
# Parameters:
#   airflow-ci-apt-deps - airflow CI dependencies image
############################################################################################################

FROM airflow-ci-apt-deps as wheel-cache

SHELL ["/bin/bash", "-xc"]

ARG CASS_DRIVER_BUILD_CONCURRENCY
ARG CASS_DRIVER_NO_CYTHON
ENV CASS_DRIVER_BUILD_CONCURRENCY=${CASS_DRIVER_BUILD_CONCURRENCY}
ENV CASS_DRIVER_NO_CYTHON=${CASS_DRIVER_NO_CYTHON}

WORKDIR /opt/airflow

# Airflow sources change frequently but dependency onfiguration won't change that often
# We copy setup.py and other files needed to perform setup of dependencies
# This way cache here will only be invalidated if any of the
# version/setup configuration change but not when airflow sources change
#
# We might also skip building the cache at all by specifying BUILD_WHEEL_CACHE=false build argument
# This is a hack that prevents to run the "pip wheel" below when we just want to build the main image
# The problem is that "wheel-cache" image is in the Docker file before main image and it will always
# be built before main image (this is how Docker build works now).
#
# In the future we can get rid of this hack. Buildkit that is an experimental feature in Docker as of
# now (Docker 18.09.2) will have the capability of skipping unused images from the multi-stage build
# and we will be able to get rid of that hacky "if BUILD_WHEEL_CACHE" below.
#
COPY setup.py /opt/airflow/setup.py
COPY setup.cfg /opt/airflow/setup.cfg

COPY airflow/version.py /opt/airflow/airflow/version.py
COPY airflow/__init__.py /opt/airflow/airflow/__init__.py
COPY airflow/bin/airflow /opt/airflow/airflow/bin/airflow

RUN mkdir -pv /cache

ARG AIRFLOW_CI_EXTRAS="devel_ci"
ENV AIRFLOW_CI_EXTRAS=${AIRFLOW_CI_EXTRAS}

ARG BUILD_WHEEL_CACHE
ENV BUILD_WHEEL_CACHE=${BUILD_WHEEL_CACHE}

ARG PIP_VERSION
ENV PIP_VERSION=${PIP_VERSION}
RUN echo "Pip version: ${PIP_VERSION}"

# Prepare wheels cache so that it can be mounted by CI images when rebuilt
RUN if [[ "${BUILD_WHEEL_CACHE}" == "true" ]]; then  \
        echo "Building wheel cache with CI extras: ${AIRFLOW_CI_EXTRAS}." ;\
        pip install --upgrade pip==${PIP_VERSION} && \
        pip wheel --no-use-pep517 --progress-bar off \
           -w /cache/.wheelhouse \
           -f /cache/.wheelhouse \
           -e ".[${AIRFLOW_CI_EXTRAS}]" ; \
    else \
        echo "Not building wheels - we are skipping that to save time !"; \
    fi

############################################################################################################
# This is the target image - it installs PIP and NPN dependencies including efficient caching
# mechanisms - it might be used to build the bare airflow build or CI build and it can optionally use
# Wheel cache image prepared earlier (very useful for fast CI rebuilds of images)
# Parameters:
#    APT_DEPS_IMAGE - image with APT dependencies. It might either be base deps image with airflow
#                     dependencies or CI deps image that contains also CI-required dependencies
#    wheel-cache-master  - this is an image with wheels built in the /cache directory.
#                            For CI builds this image is not rebuilt every time but the one from previous
#                            DockerHub master build. This saves time for buildig the CI image in case
#                            dependencies change. For non-CI images wheel-cache-master /cache directory
#                            should be empty which should decrease size of the final image.
############################################################################################################
FROM ${APT_DEPS_IMAGE} as main

WORKDIR /opt/airflow

RUN echo "Airflow version: ${AIRFLOW_VERSION}"

ARG AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW_HOME=${AIRFLOW_HOME}

USER airflow

RUN sudo -E mkdir -pv ${AIRFLOW_HOME} && \
    sudo -E chown -R airflow.airflow ${AIRFLOW_HOME}

COPY --chown=airflow:airflow --from=wheel-cache-master /cache /cache

# Increase the value here to force reinstalling Apache Airflow pip dependencies
ENV FORCE_REINSTALL_ALL_PIP_DEPENDENCIES=1

ARG CASS_DRIVER_BUILD_CONCURRENCY
ARG CASS_DRIVER_NO_CYTHON
ENV CASS_DRIVER_BUILD_CONCURRENCY=${CASS_DRIVER_BUILD_CONCURRENCY}
ENV CASS_DRIVER_NO_CYTHON=${CASS_DRIVER_NO_CYTHON}

# Airflow sources change frequently but dependency onfiguration won't change that often
# We copy setup.py and other files needed to perform setup of dependencies
# This way cache here will only be invalidated if any of the
# version/setup configuration change but not when airflow sources change
COPY --chown=airflow:airflow setup.py /opt/airflow/setup.py
COPY --chown=airflow:airflow setup.cfg /opt/airflow/setup.cfg

COPY --chown=airflow:airflow airflow/version.py /opt/airflow/airflow/version.py
COPY --chown=airflow:airflow airflow/__init__.py /opt/airflow/airflow/__init__.py
COPY --chown=airflow:airflow airflow/bin/airflow /opt/airflow/airflow/bin/airflow


ARG AIRFLOW_EXTRAS="all"
ENV AIRFLOW_EXTRAS=${AIRFLOW_EXTRAS}
RUN echo "Installing with extras: ${AIRFLOW_EXTRAS}."

ARG PIP_CACHE_DIRECTIVE
ENV PIP_CACHE_DIRECTIVE=${PIP_CACHE_DIRECTIVE}
RUN echo "Pip cache directive: ${PIP_CACHE_DIRECTIVE}."

ARG PIP_VERSION
ENV PIP_VERSION=${PIP_VERSION}
RUN echo "Pip version: ${PIP_VERSION}"

# First install only dependencies but no Apache Airflow itself
# This way regular changes in sources of Airflow will not trigger reinstallation of all dependencies
# And this Docker layer will be reused between builds.
RUN sudo -E pip install ${PIP_CACHE_DIRECTIVE} --upgrade pip==${PIP_VERSION} && \
    sudo -E pip install ${PIP_CACHE_DIRECTIVE} --no-use-pep517 -e ".[${AIRFLOW_EXTRAS}]"

COPY --chown=airflow:airflow airflow/www/package.json /opt/airflow/airflow/www/package.json
COPY --chown=airflow:airflow airflow/www/package-lock.json /opt/airflow/airflow/www/package-lock.json

WORKDIR /opt/airflow/airflow/www

# Install necessary NPM dependencies (triggered by changes in package-lock.json)
RUN npm ci

COPY --chown=airflow:airflow airflow/www/ /opt/airflow/airflow/www/

# Package NPM for production
RUN npm run prod

WORKDIR /opt/airflow

# Cache for this line will be automatically invalidated if any
# of airflow sources change
COPY --chown=airflow:airflow . /opt/airflow/

# Always add-get update/upgrade here to get latest dependencies before
# we redo pip install
RUN sudo -E apt-get update \
    && sudo -E apt-get upgrade -y --no-install-recommends \
    && sudo -E apt-get clean && sudo rm -rf /var/lib/apt/lists/*

# Additional python dependencies
ARG ADDITIONAL_PYTHON_DEPS

RUN if [ -n "${ADDITIONAL_PYTHON_DEPS}" ]; then \
        sudo -E pip install ${PIP_CACHE_DIRECTIVE} ${ADDITIONAL_PYTHON_DEPS}; \
    fi

COPY --chown=airflow:airflow .bash_aliases /home/airflow/.bash_aliases
COPY --chown=airflow:airflow .inputrc /home/airflow/.inputrc

WORKDIR ${AIRFLOW_HOME}

COPY --chown=airflow:airflow ./scripts/docker/entrypoint.sh /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dumb-init", "--", "/entrypoint.sh"]
CMD ["--help"]
