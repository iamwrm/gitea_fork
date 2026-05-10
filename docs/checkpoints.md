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
