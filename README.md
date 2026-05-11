# Forgejo and Gitea Archive/HTML Preview Patch Set

This repository tracks patch artifacts and implementation notes for adding archive browsing and HTML preview support to Forgejo and Gitea repository file views.

## Repository layout

- `docs/checkpoints.md` — chronological notes about the local workspaces, implemented behavior, and verification commands.
- `docs/forgejo-archive-html-preview.patch` — patch generated from `local_data/forgejo` for Forgejo.
- `docs/gitea-archive-html-preview.patch` — patch generated from `local_data/gitea` for Gitea `v1.26.1`.
- `docs/publish-forgejo-ghcr.md` — build and publish workflow for a patched Forgejo GHCR image.
- `container/Dockerfile.patched-forgejo` — wrapper image build that copies patched binaries into an upstream Forgejo runtime image.
- `scripts/publish-forgejo-ghcr.sh` — GHCR build/publish helper with upstream-derived version tags.
- `local_data/` — ignored local checkouts, builds, test data, and generated assets.

## Implemented features

### Archive preview

Both patch artifacts add repository file-view support for browsing `.zip` and `.tar.gz` files:

- top-level and nested archive directory listings,
- `archive_path` navigation for entries inside archives,
- syntax-highlighted text-file previews,
- inline image previews through data URIs,
- graceful errors for unsupported binary entries,
- archive-aware raw downloads for selected files and generated `.zip` downloads for selected directories.

### HTML preview

Both patch artifacts add rendered/source toggle support for `.html` and `.htm` files:

- rendered HTML is shown in a sandboxed iframe,
- the iframe permits scripts without same-origin access,
- `/render/...` serves HTML and sibling plain-text assets with extension-based MIME types, allowing static assets such as JavaScript to load correctly,
- integration tests cover rendered/source views and render endpoint content types.

## Verification recorded in docs

The notes in `docs/checkpoints.md` record successful backend builds, targeted integration tests, `git diff --check`, and reverse patch checks for the generated patch artifacts.

## Patched GHCR container

The container workflow in `docs/publish-forgejo-ghcr.md` reuses the upstream Forgejo runtime image and replaces only the patched Forgejo binary plus `environment-to-ini`.

For the current Forgejo checkout, the derived upstream version is:

```text
16.0.0-dev-243-69cf1f3333+gitea-1.22.0
```

The published GHCR image is:

```text
ghcr.io/iamwrm/gitea_fork/forgejo:16.0.0-dev-243-69cf1f3333-archive-html-preview-gitea-1.22.0
```
