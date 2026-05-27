# actions-runner

Custom GitHub Actions self-hosted runner image for airplanes.live ARC.

Thin layer on top of the official [`ghcr.io/actions/actions-runner`](https://github.com/actions/runner/pkgs/container/actions-runner) base, adding a C toolchain (`build-essential`) so cgo builds (`go test -race`) work without a per-job `apt-get`. The base image ships Docker CLI + Buildx; those are untouched.

We don't use a community runner image (e.g. `catthehacker/ubuntu`) — single-maintainer supply-chain exposure. A pinned Dockerfile on GitHub's official base keeps us on a patched image we control.

## Consuming it in ARC

Two independent knobs need to be set in the `gha-runner-scale-set` Helm values:

1. **Runner image** — the toolchain this repo provides.
2. **`containerMode: dind`** — a Docker-in-Docker sidecar that provides a Docker daemon for image builds (the runner image only has the client). This is separate from the image.

```yaml
template:
  spec:
    nodeSelector:
      kubernetes.io/arch: amd64
    imagePullSecrets:
      - name: ghcr-pull              # see "GHCR access" below
    containers:
      - name: runner                  # ARC requires this name
        image: ghcr.io/airplanes-live/actions-runner:2.334.0
        imagePullPolicy: Always       # tag is mutable across rebuilds
        command: ["/home/runner/run.sh"]
containerMode:
  type: dind        # Docker daemon sidecar; requires privileged pods
```

**Notes:**

- `dind` requires privileged pods — may be blocked by Pod Security Admission or policy engines. Verify the cluster allows it before rolling out.
- If the dind sidecar itself needs customisation (image, security context), `containerMode` must be replaced with a full pod spec per the [ARC docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/deploying-runner-scale-sets-with-actions-runner-controller#using-docker-in-docker-mode).

## GHCR access

This package is private. ARC pods need an `imagePullSecret` whose token has `read:packages` scope — anonymous pulls fail for private GHCR packages.

Preflight: `docker pull ghcr.io/airplanes-live/actions-runner:<tag>` from a cluster node using the same credentials before switching Helm values.

## Updates

[Dependabot](.github/dependabot.yml) opens PRs weekly:

- **`docker` ecosystem** bumps the `FROM` runner version when GitHub cuts a new release.
- **`github-actions` ecosystem** bumps the pinned action SHAs in the build workflow.

PR builds validate the image (build + smoke test) without publishing. Merging to `main` triggers a build that publishes to GHCR.

GitHub requires self-hosted runners to stay within ~30 days of the latest release — treat runner-version Dependabot PRs as time-sensitive.
