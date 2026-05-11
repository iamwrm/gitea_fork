# Publishing the Patched Forgejo Container to GHCR

This workflow packages the patched Forgejo checkout in `local_data/forgejo` while reusing the upstream Forgejo container image as the final runtime image.

The wrapper Dockerfile builds only the patched `gitea`/`forgejo` binary and `environment-to-ini`, then copies those files into an upstream runtime image such as:

```sh
codeberg.org/forgejo/forgejo:15.0.1
```

Forgejo's Docker installation docs use `codeberg.org/forgejo/forgejo` as the image name and note that `data.forgejo.org` can be used as a mirror when Codeberg is unavailable.

## Published Image

The patched image has been published to the package namespace for this GitHub repository:

```text
ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0
```

Remote manifest digest:

```text
sha256:915ad7c808714e30e56641467ee69faf23d561d1434aab7bd68e1c693ac1defb
```

The GHCR package is associated with `iamwrm/gitea_fork`. The image config labels keep that package source explicit while recording the reused upstream runtime image:

```text
org.opencontainers.image.source=https://github.com/iamwrm/gitea_fork
org.opencontainers.image.base.name=codeberg.org/forgejo/forgejo:15.0.1
org.opencontainers.image.version=16.0.0-dev-243-69cf1f3333-archive-html-preview+gitea-1.22.0
```

## Version Tag

The publish script derives the upstream version from the Forgejo checkout:

```sh
make -C local_data/forgejo -s show-version-full
```

For the current checkout this resolves to:

```text
16.0.0-dev-243-69cf1f3333+gitea-1.22.0
```

The patched release version appends the patch name before the compatibility suffix:

```text
16.0.0-dev-243-69cf1f3333-archive-html-preview+gitea-1.22.0
```

Docker tags cannot contain `+`, so the pushed image tag replaces `+` with `-`:

```text
16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0
```

This keeps the upstream Forgejo version and commit visible in the tag while marking the image as patched.

## Build Or Publish

The helper defaults `IMAGE_REPO` to `ghcr.io/<github-owner>/<github-repo>/forgejo` and `IMAGE_SOURCE` to the current GitHub repository URL by reading the repository with `gh repo view`.

Build locally:

```sh
UPSTREAM_IMAGE=codeberg.org/forgejo/forgejo:15.0.1 \
scripts/publish-forgejo-ghcr.sh
```

Publish to GHCR:

```sh
gh auth refresh -h github.com -s write:packages
UPSTREAM_IMAGE=codeberg.org/forgejo/forgejo:15.0.1 \
PUSH=1 \
scripts/publish-forgejo-ghcr.sh
```

Push an already-built local tag without rebuilding:

```sh
PUSH_EXISTING=1 \
scripts/publish-forgejo-ghcr.sh
```

## Restore Saved Image

The verified image was also saved under ignored local storage:

```text
local_data/images/forgejo-16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0.tar.gz
```

Archive checksum:

```text
9566960d91696d438e87ab3c00fd7dc4b1fee68307cdc65531cbc30840d80891
```

The saved archive contains the published GHCR tag. To restore and push it to GHCR without rebuilding:

```sh
sha256sum -c <<'EOF'
9566960d91696d438e87ab3c00fd7dc4b1fee68307cdc65531cbc30840d80891  local_data/images/forgejo-16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0.tar.gz
EOF
gunzip -c local_data/images/forgejo-16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0.tar.gz | docker load
IMAGE_REPO=ghcr.io/iamwrm/gitea_fork/forgejo \
PUSH_EXISTING=1 \
scripts/publish-forgejo-ghcr.sh
```

## Important Override for Dev Checkouts

The current Forgejo checkout is based on a development commit. The exact default upstream runtime image,

```text
codeberg.org/forgejo/forgejo:16.0.0-dev-243-69cf1f3333
```

is not currently published publicly. Set `UPSTREAM_IMAGE` to the closest upstream runtime image you intentionally want to reuse.

Use the matching root/rootless upstream image family for your deployment. The wrapper Dockerfile inherits the upstream entrypoint, user, ports, volumes, runtime packages, and filesystem layout from that image.

## Common Variables

- `IMAGE_REPO`: full target repository, default `ghcr.io/<github-owner>/<github-repo>/forgejo`.
- `IMAGE_SOURCE`: GitHub repository URL for GHCR package association, default current repository URL.
- `IMAGE_NAME`: target image name under the repository package namespace, default `forgejo`.
- `IMAGE_TAG`: explicit Docker tag override.
- `RELEASE_VERSION`: explicit Forgejo runtime version string override.
- `UPSTREAM_IMAGE`: exact upstream runtime image to reuse.
- `UPSTREAM_IMAGE_TAG`: tag used with `codeberg.org/forgejo/forgejo` when `UPSTREAM_IMAGE` is not set.
- `PLATFORMS`: buildx platform list, default `linux/amd64`.
- `PUSH=1`: push instead of loading into the local Docker daemon.
- `PUSH_EXISTING=1`: push the already-built local image tag without rebuilding.
- `DRY_RUN=1`: print the derived image inputs without invoking Docker.
- `SKIP_UPSTREAM_CHECK=1`: skip the preflight `docker manifest inspect` check.
- `SKIP_GHCR_AUTH_CHECK=1`: skip the preflight `gh auth status` and GHCR login check.
