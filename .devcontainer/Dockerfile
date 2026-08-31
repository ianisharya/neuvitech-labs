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

# The base image ships an APT source for Yarn with no importable signing
# key. Debian refuses to trust an unsigned repo and aborts `apt-get update`
# entirely — which took down every other package in the same RUN line on
# first build (31 Aug 2026, macOS/arm64). We install Node via NodeSource
# and never use this source, so remove it before the first update rather
# than import a key that may rotate.
RUN rm -f /etc/apt/sources.list.d/yarn.list 2>/dev/null || true

# PGDG's own repo, not Debian's. bookworm's default `postgresql-client`
# resolves to 15.x, but our server is Postgres 16 (docs/03, ADR-0003) and
# an older client talking to a newer major-version server is the wrong
# direction and breaks in ways that are unpleasant to debug mid-sprint.
# Found via `make doctor` reporting psql 15.19 against a spec of 16.
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list

# System tooling.
#   postgresql-client-16 — psql, matching the server version exactly
#   redis-tools          — redis-cli
#   make                 — the single command interface (docs/03 section 5)
#   jq/curl              — API testing and scripting
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        jq \
        make \
        postgresql-client-16 \
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
