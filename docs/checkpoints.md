# Checkpoints

## Workspace layout

- Initialized `/ssd/try_forgejo_explore_zip` as the wrapper git repository.
- Moved the Forgejo working tree to `local_data/forgejo`.
- Added `local_data/` to the wrapper `.gitignore` so the full Forgejo checkout, build output, test database, and node modules stay outside the wrapper repo.
- Updated `local_data/forgejo/tests/sqlite.ini` so Forgejo's `WORK_PATH` points at `/ssd/try_forgejo_explore_zip/local_data/forgejo`.

## Forgejo archive preview work

- Added archive browsing for `.zip` and `.tar.gz` files in the repository file view.
- Archive entries can be navigated with `archive_path`.
- Directories render as a table of immediate children.
- Text files inside archives render through Forgejo's normal code view.
- Image files inside archives render inline from a data URI.
- Unsupported binary archive entries show a preview error instead of a raw file listing.
- Added archive-aware raw download behavior:
  - selected archive files download that entry,
  - selected archive directories download a generated `.zip`,
  - archive root behavior stays as the original archive file.

## Forgejo HTML preview work

- Added rendered/source toggle support for `.html` and `.htm` files.
- Rendered HTML opens in a sandboxed iframe using `/render/...`.
- The iframe allows scripts but not same-origin access.
- `/render/...` now serves plain text assets with extension-based MIME types, so sibling static assets such as `.js` can load with the right content type.
- Added integration coverage for the HTML preview path and render endpoint content types.

## Test repository state

- Added `tools/hash-base64-time.html` to `forgejo-admin/repo1` as a sample static HTML tooling page.
- Replayed the skipped Forgejo `post-receive` hook after a direct bare-repository push.
- Ran `doctor synchronize-repo-heads` so the test repository metadata is back in sync.

## Verification already run

- `go test -tags='sqlite sqlite_unlock_notify' ./routers/web/repo -run TestDoesNotExist -count=0`
- `go test -tags='sqlite sqlite_unlock_notify' ./tests/integration -run TestRepoViewArchiveFiles -count=1`
- `go test -tags='sqlite sqlite_unlock_notify' ./tests/integration -run 'TestRepoViewHTMLPreview|TestRepoViewArchiveFiles' -count=1`
- `make backend TAGS='sqlite sqlite_unlock_notify'`

## Patch artifact

- `docs/forgejo-archive-html-preview.patch` contains the current Forgejo code changes generated from `local_data/forgejo`.

## Forgejo patched container publishing

- Added `container/Dockerfile.patched-forgejo` to build the patched Forgejo binary from `local_data/forgejo` while reusing an upstream Forgejo runtime image as the final image.
- Added `scripts/publish-forgejo-ghcr.sh` to build or publish the patched image to GHCR.
- Added `docs/publish-forgejo-ghcr.md` with the GHCR publishing workflow, runtime-image override guidance, and tag/version rules.
- The script derives the current upstream Forgejo version with `make -C local_data/forgejo -s show-version-full`.
- Current derived upstream version: `16.0.0-dev-243-69cf1f3333+gitea-1.22.0`.
- Default patched release version: `16.0.0-dev-243-69cf1f3333-archive-html-preview+gitea-1.22.0`.
- Default Docker-safe image tag: `16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`.
- Verified `codeberg.org/forgejo/forgejo:16.0.0-dev-243-69cf1f3333` is not currently published, so `UPSTREAM_IMAGE` must be set before publishing this dev checkout.
- Verified `codeberg.org/forgejo/forgejo:15` and `codeberg.org/forgejo/forgejo:15.0.1` are published upstream runtime images.
- Verification run:
  - `bash -n scripts/publish-forgejo-ghcr.sh`
  - `DRY_RUN=1 scripts/publish-forgejo-ghcr.sh`
  - `docker manifest inspect codeberg.org/forgejo/forgejo:16.0.0-dev-243-69cf1f3333`
  - `docker manifest inspect codeberg.org/forgejo/forgejo:15`
  - `docker manifest inspect codeberg.org/forgejo/forgejo:15.0.1`
- First publish attempt with `UPSTREAM_IMAGE=codeberg.org/forgejo/forgejo:15.0.1` failed during the containerized Go compile because the Docker host filesystem had no free space.
- Cleared Docker, Go, and npm build caches, then reduced containerized Go compile parallelism with `GOFLAGS="-trimpath -p=1"` to lower temporary disk pressure.
- Second publish attempt built the local image successfully:
  - image: `gcr.io/iamwrm1/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`
  - image ID: `sha256:33f115ae247fe2942c59e2ee2715cf32180c262cecf54f28658a4575532d9a97`
  - base label: `org.opencontainers.image.base.name=codeberg.org/forgejo/forgejo:15.0.1`
  - release label: `org.opencontainers.image.version=16.0.0-dev-243-69cf1f3333-archive-html-preview+gitea-1.22.0`
- Verified local image version output:
  - `forgejo version 16.0.0-dev-243-69cf1f3333+gitea-1.22.0 (release name 16.0.0-dev-243-69cf1f3333-archive-html-preview+gitea-1.22.0) built with GNU Make 4.4.1, go1.26.3 : bindata, timetzdata, sqlite, sqlite_unlock_notify`
- Earlier GCR push did not complete because `gcloud` credentials were expired:
  - `gcloud auth print-access-token` fails with `invalid_grant: Bad Request`.
- Switched the publishing target to GHCR after confirming `gh` was authenticated and then refreshing the token with `write:packages`.
- Added `PUSH_EXISTING=1` to push an already-built local image tag without rebuilding.
- Refreshed GitHub CLI auth with `write:packages`, logged Docker in to GHCR with the `gh` token, and pushed an initial GHCR image:
  - image: `ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`
  - manifest digest: `sha256:452c8fcc63ea78a5821f95dca044edf78534db49471591162fcdef6d116c70b0`
  - config digest: `sha256:33f115ae247fe2942c59e2ee2715cf32180c262cecf54f28658a4575532d9a97`
- Audited the GHCR package metadata and found the initial package had no repository association because `org.opencontainers.image.source` pointed at the upstream Codeberg repository.
- Updated `container/Dockerfile.patched-forgejo` and `scripts/publish-forgejo-ghcr.sh` so `org.opencontainers.image.source` defaults to `https://github.com/iamwrm/gitea_fork` while `org.opencontainers.image.base.name` records the reused upstream runtime image.
- Rebuilt and repushed the same GHCR tag:
  - image: `ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`
  - manifest digest: `sha256:915ad7c808714e30e56641467ee69faf23d561d1434aab7bd68e1c693ac1defb`
  - config digest: `sha256:d89162df0d464952545b3ed0f0d5c315ec69c0190341590016f300b360f0440d`
  - source label: `org.opencontainers.image.source=https://github.com/iamwrm/gitea_fork`
  - base label: `org.opencontainers.image.base.name=codeberg.org/forgejo/forgejo:15.0.1`
  - GHCR package repository association: `iamwrm/gitea_fork`
- Saved the current GHCR image to ignored local storage for recovery without rebuilding:
  - `local_data/images/forgejo-16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0.tar.gz`
  - SHA256: `9566960d91696d438e87ab3c00fd7dc4b1fee68307cdc65531cbc30840d80891`
- Verified GHCR publish:
  - `docker manifest inspect ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`
  - `docker buildx imagetools inspect ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0`
  - `gh api /user/packages/container/gitea_fork%2Fforgejo/versions --paginate`
  - `gh api /user/packages/container/gitea_fork%2Fforgejo`
  - `docker run --rm ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0 forgejo --version`

## Gitea latest-release archive preview work

- Ported the Forgejo archive preview behavior to Gitea `v1.26.1`.
- Added archive browsing for `.zip` and `.tar.gz` repository files.
- Archive entries can be navigated with `archive_path`.
- Directories render as a table of immediate children.
- Text files inside archives render through Gitea's normal code view.
- Image files inside archives render inline from a data URI.
- Unsupported binary archive entries show a preview error instead of a raw file listing.
- Added archive-aware raw download behavior:
  - selected archive files download that entry,
  - selected archive directories download a generated `.zip`,
  - archive root behavior stays as the original archive file.

## Gitea latest-release HTML preview work

- Added rendered/source toggle support for `.html` and `.htm` files.
- Rendered HTML opens in a sandboxed iframe using `/render/...`.
- The iframe allows scripts but not same-origin access.
- `/render/...` now serves HTML preview files and sibling plain-text assets with extension-based MIME types, so files such as `.js` load with the right content type.
- Added integration coverage for the HTML preview path and render endpoint content types.

## Gitea verification already run

- `go test -tags='sqlite sqlite_unlock_notify' ./routers/web/repo -run TestDoesNotExist -count=0`
- `GITEA_TEST_CONF=tests/sqlite.ini go test -tags='sqlite sqlite_unlock_notify' ./tests/integration -run 'TestRepoViewArchiveFiles|TestRepoViewHTMLPreview' -count=1`
- `go build -tags='sqlite sqlite_unlock_notify' -o gitea`
- `git diff --check`
- `git apply --reverse --check docs/gitea-archive-html-preview.patch`

## Gitea local test server

- Built frontend assets with `make frontend` so `/assets/...` files are available.
- Updated generated `local_data/gitea/tests/sqlite.ini` for local testing on `http://localhost:3004/`.
- Set `STATIC_ROOT_PATH` to the Gitea checkout so templates and public assets resolve correctly.
- Created local admin account:
  - username: `admin`
  - password: `password`
- Confirmed the server renders the home page and serves the hashed frontend asset `assets/js/iife.DYEzIdse.js`.

## Gitea patch artifact

- `docs/gitea-archive-html-preview.patch` contains the current Gitea code changes generated from `local_data/gitea`.
