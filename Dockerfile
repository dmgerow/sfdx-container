FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG SALESFORCE_CLI_VERSION=latest-rc
ARG SF_CLI_VERSION=latest-rc

####### Install Pre-reqs
RUN apt-get update && apt-get install --assume-yes \
        curl \
        git

####### Install Node
RUN echo 'a0f23911d5d9c371e95ad19e4e538d19bffc0965700f187840eb39a91b0c3fb0  ./nodejs.tar.gz' > node-file-lock.sha \
    && curl -s -o nodejs.tar.gz https://nodejs.org/dist/v16.13.2/node-v16.13.2-linux-x64.tar.gz \
    && shasum --check node-file-lock.sha
RUN mkdir /usr/local/lib/nodejs \
    && tar xf nodejs.tar.gz -C /usr/local/lib/nodejs/ --strip-components 1 \
    && rm nodejs.tar.gz node-file-lock.sha

####### Install Java
RUN apt-get update && apt-get install --assume-yes openjdk-11-jdk-headless jq
RUN apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/*

####### Set XDG environment variables explicitly so that GitHub Actions does not apply
####### default paths that do not point to the plugins directory
####### https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
ENV XDG_DATA_HOME=/sfdx_plugins/.local/share
ENV XDG_CONFIG_HOME=/sfdx_plugins/.config
ENV XDG_CACHE_HOME=/sfdx_plugins/.cache

####### Create isolated plugins directory with rwx permission for all users
####### Azure pipelines switches to a container-user which does not have access
####### to the root directory where plugins are normally installed
RUN mkdir -p $XDG_DATA_HOME && \
    mkdir -p $XDG_CONFIG_HOME && \
    mkdir -p $XDG_CACHE_HOME && \
    chmod -R 777 sfdx_plugins

RUN export XDG_DATA_HOME && \
    export XDG_CONFIG_HOME && \
    export XDG_CACHE_HOME

####### Install SFDX CLI
ENV PATH=/usr/local/lib/nodejs/bin:$PATH
RUN npm install --global sfdx-cli@${SALESFORCE_CLI_VERSION} --ignore-scripts
RUN npm install --global @salesforce/cli@${SF_CLI_VERSION}

####### Install sfdx plugins
RUN echo 'y' | sfdx plugins:install sfdmu
RUN echo 'y' | sfdx plugins:install sfdx-git-delta
RUN sfdx plugins:install @salesforce/sfdx-scanner

ENV SFDX_CONTAINER_MODE true
ENV DEBIAN_FRONTEND=dialog
ENV SHELL /bin/bash