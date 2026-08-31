# NeuViTech Labs development image.
#
# Every version here is pinned. Nothing floats. A toolchain that changes
# without a reviewed pull request is both a reproducibility bug and a
# supply-chain risk.
#
# Digest pinning: replace the tag with a @sha256 digest once the first build
# succeeds on both machines (Sprint 1, Day 7). Recorded as NVL-103 follow-up.
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System tooling.
#   postgresql-client — psql, for inspecting the database directly
#   redis-tools       — redis-cli
#   make              — the single command interface (docs/03 section 5)
#   jq/curl           — API testing and scripting
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        jq \
        make \
        postgresql-client \
        redis-tools \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS — pinned major, matches CI.
ARG NODE_MAJOR=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@10

# uv — the mandated Python project manager (ADR-0005).
ARG UV_VERSION=0.5.11
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx \
    && chmod 755 /usr/local/bin/uv /usr/local/bin/uvx

USER vscode
WORKDIR /workspaces/neuvitech-labs
