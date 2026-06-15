FROM python:3.12-slim AS python-base

FROM node:24-slim AS node-base

FROM eclipse-temurin:21-jdk AS java-base

FROM nousresearch/hermes-agent:latest
USER root

# Install system dependencies that might be needed by Python/Node/Java
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    libsqlite3-0 \
    libffi8 \
    libssl3 \
    zlib1g \
    libbz2-1.0 \
    liblzma5 \
    libreadline8 \
    libncursesw6 \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Copy python 3.12 files
COPY --from=python-base /usr/local /usr/local
RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python12

# Copy node 24 files (specifically copy binaries and node_modules to avoid overwriting /usr/local completely)
COPY --from=node-base /usr/local/bin/node /usr/local/bin/node
COPY --from=node-base /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Copy java 21 files
COPY --from=java-base /opt/java/openjdk /opt/java/openjdk

# Set Java environment variables
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="/opt/java/openjdk/bin:${PATH}"

# Switch back to the default user if the base image has one, or stay root.
# The base image has user root by default for initialization, so we can stay root or let the entrypoint handle it.
