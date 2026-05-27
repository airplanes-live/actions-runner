# Custom GitHub Actions self-hosted runner image for airplanes.live ARC.
# Official runner image + a C toolchain so cgo builds (e.g. `go test -race`)
# work without a per-job apt-get. Docker-in-Docker for image builds is a
# separate concern, handled by `containerMode: dind` in the ARC Helm values,
# not by this image.
FROM ghcr.io/actions/actions-runner:2.334.0

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*
USER runner
