# Forgejo and Gitea Archive/HTML Preview Patch Set

This repository tracks patch artifacts and implementation notes for adding archive browsing and HTML preview support to Forgejo and Gitea repository file views.

## Repository layout

- `docs/checkpoints.md` — chronological notes about the local workspaces, implemented behavior, and verification commands.
- `docs/forgejo-archive-html-preview.patch` — patch generated from `local_data/forgejo` for Forgejo.
- `docs/gitea-archive-html-preview.patch` — patch generated from `local_data/gitea` for Gitea `v1.26.1`.
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
