# Custom GitHub Actions self-hosted runner image for airplanes.live ARC.
# Official runner image + a C toolchain so cgo builds (e.g. `go test -race`)
# work without a per-job apt-get, plus the Docker Compose CLI plugin so
# Compose-based jobs work without a per-job download. Docker-in-Docker for
# image builds is a separate concern, handled by `containerMode: dind` in the
# ARC Helm values, not by this image.
FROM ghcr.io/actions/actions-runner:2.334.0

# Docker Compose CLI plugin, pinned + checksum-verified, installed to the global
# CLI plugin path so `docker compose` resolves for the runner user. The base
# image ships the Docker CLI + Buildx but not Compose. Build is linux/amd64 only.
ARG COMPOSE_VERSION=v5.1.4
ARG COMPOSE_SHA256=33b208d7e76639db742fae84b966cc01dacae58ca3fc4dabbc907045aefdf0c4

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-compose \
        "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    && echo "${COMPOSE_SHA256}  /usr/local/lib/docker/cli-plugins/docker-compose" | sha256sum -c - \
    && chmod 0755 /usr/local/lib/docker/cli-plugins/docker-compose \
    && /usr/local/lib/docker/cli-plugins/docker-compose version
USER runner
