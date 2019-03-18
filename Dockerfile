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
ARG AIRFLOW_VERSION="2.0.0.dev0"
# Which image is used as dependency for the main image
ARG APT_DEPS_IMAGE="airflow-apt-deps"
# Speeds up building the image - cassandra driver without CYTHON saves around 10 minutes
ARG CASS_DRIVER_NO_CYTHON="1"
# Build cassandra driver on multiple CPUs
ARG CASS_DRIVER_BUILD_CONCURRENCY="8"
# By default PIP install is run without cache to make image smaller
ARG PIP_CACHE_DIRECTIVE="--no-cache-dir"
# Additional python deps to install
ARG ADDITIONAL_PYTHON_DEPS=""
# PIP version used to install dependencies
ARG PIP_VERSION="19.0.1"
# By increasing this number we can do force build of all dependencies
ARG FORCE_REINSTALL_ALL_DEPENDENCIES="1"
############################################################################################################
# This is base image with APT dependencies needed by Airflow. It is based on a python slim image
# Parameters:
#    PYTHON_BASE_IMAGE - base python image (python:x.y-slim)
############################################################################################################
FROM ${PYTHON_BASE_IMAGE} as airflow-apt-deps

SHELL ["/bin/bash", "-o", "pipefail", "-e", "-u", "-x", "-c"]

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
ENV FORCE_REINSTALL_ALL_DEPENDENCIES=${FORCE_REINSTALL_ALL_DEPENDENCIES}

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
           nodejs gosu sudo \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN adduser airflow \
    && echo "airflow ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/airflow \
    && chmod 0440 /etc/sudoers.d/airflow

############################################################################################################
# This is the target image - it installs PIP and NPN dependencies including efficient caching
# mechanisms - it might be used to build the bare airflow build or CI build
# Parameters:
#    APT_DEPS_IMAGE - image with APT dependencies. It might either be base deps image with airflow
#                     dependencies or CI deps image that contains also CI-required dependencies
############################################################################################################
FROM airflow-apt-deps as main

SHELL ["/bin/bash", "-o", "pipefail", "-e", "-u", "-x", "-c"]

WORKDIR /opt/airflow

RUN echo "Airflow version: ${AIRFLOW_VERSION}"

ARG AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW_HOME=${AIRFLOW_HOME}

RUN mkdir -pv ${AIRFLOW_HOME} \
    && chown -R airflow.airflow ${AIRFLOW_HOME}

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
RUN pip install ${PIP_CACHE_DIRECTIVE} --upgrade pip==${PIP_VERSION} \
    && pip install ${PIP_CACHE_DIRECTIVE} --no-use-pep517 -e ".[${AIRFLOW_EXTRAS}]"

COPY --chown=airflow:airflow airflow/www/package.json /opt/airflow/airflow/www/package.json
COPY --chown=airflow:airflow airflow/www/package-lock.json /opt/airflow/airflow/www/package-lock.json

WORKDIR /opt/airflow/airflow/www

# Install necessary NPM dependencies (triggered by changes in package-lock.json)
RUN gosu airflow npm ci

COPY --chown=airflow:airflow airflow/www/ /opt/airflow/airflow/www/

# Package NPM for production
RUN gosu airflow npm run prod

WORKDIR /opt/airflow

# Cache for this line will be automatically invalidated if any
# of airflow sources change
COPY --chown=airflow:airflow . /opt/airflow/

# Always add-get update/upgrade here to get latest dependencies before
# we redo pip install
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Additional python dependencies
ARG ADDITIONAL_PYTHON_DEPS

RUN if [ -n "${ADDITIONAL_PYTHON_DEPS}" ]; then \
        pip install ${PIP_CACHE_DIRECTIVE} ${ADDITIONAL_PYTHON_DEPS}; \
    fi

USER airflow

WORKDIR ${AIRFLOW_HOME}

COPY --chown=airflow:airflow ./scripts/docker/entrypoint.sh /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/dumb-init", "--", "/entrypoint.sh"]
CMD ["--help"]
