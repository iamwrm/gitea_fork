#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGEJO_DIR="${FORGEJO_DIR:-${ROOT_DIR}/local_data/forgejo}"
DOCKERFILE="${DOCKERFILE:-${ROOT_DIR}/container/Dockerfile.patched-forgejo}"
PATCH_NAME="${PATCH_NAME:-archive-html-preview}"
IMAGE_NAME="${IMAGE_NAME:-forgejo}"
PLATFORMS="${PLATFORMS:-linux/amd64}"
PUSH="${PUSH:-0}"
PUSH_EXISTING="${PUSH_EXISTING:-0}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_UPSTREAM_CHECK="${SKIP_UPSTREAM_CHECK:-0}"
SKIP_GHCR_AUTH_CHECK="${SKIP_GHCR_AUTH_CHECK:-0}"

if [[ ! -d "${FORGEJO_DIR}/.git" ]]; then
  echo "Forgejo checkout not found at ${FORGEJO_DIR}" >&2
  exit 1
fi

repo_slug="${GITHUB_REPOSITORY:-}"
repo_url=""
if [[ -z "${repo_slug}" ]]; then
  repo_info="$(gh repo view --json nameWithOwner,url --jq '[.nameWithOwner, .url] | @tsv' 2>/dev/null || true)"
  if [[ -n "${repo_info}" ]]; then
    repo_slug="${repo_info%%$'\t'*}"
    repo_url="${repo_info#*$'\t'}"
  fi
elif [[ -n "${GITHUB_SERVER_URL:-}" ]]; then
  repo_url="${GITHUB_SERVER_URL}/${repo_slug}"
else
  repo_url="https://github.com/${repo_slug}"
fi

if [[ -z "${IMAGE_REPO:-}" ]]; then
  if [[ -z "${repo_slug}" ]]; then
    echo "Set IMAGE_REPO or run from a GitHub repository checkout." >&2
    exit 1
  fi
  repo_slug="$(printf '%s' "${repo_slug}" | tr '[:upper:]' '[:lower:]')"
  IMAGE_REPO="ghcr.io/${repo_slug}/${IMAGE_NAME}"
fi

if [[ -z "${IMAGE_SOURCE:-}" ]]; then
  if [[ -z "${repo_url}" ]]; then
    echo "Set IMAGE_SOURCE to the GitHub repository URL for GHCR package association." >&2
    exit 1
  fi
  IMAGE_SOURCE="${repo_url}"
fi

upstream_version="$(
  cd "${FORGEJO_DIR}"
  make -s show-version-full
)"
base_version="${upstream_version%%+*}"
compat_suffix=""
if [[ "${upstream_version}" == *+* ]]; then
  compat_suffix="+${upstream_version#*+}"
fi

release_version="${RELEASE_VERSION:-${base_version}-${PATCH_NAME}${compat_suffix}}"
image_tag="${IMAGE_TAG:-${release_version//+/-}}"
upstream_image_tag="${UPSTREAM_IMAGE_TAG:-${base_version}}"
upstream_image="${UPSTREAM_IMAGE:-codeberg.org/forgejo/forgejo:${upstream_image_tag}}"
target_image="${IMAGE_REPO}:${image_tag}"

build_output=(--load)
if [[ "${PUSH}" == "1" ]]; then
  build_output=(--push)
fi

echo "Forgejo upstream version: ${upstream_version}"
echo "Patched release version:  ${release_version}"
echo "Upstream runtime image:   ${upstream_image}"
echo "Target image:             ${target_image}"
echo "Image source:             ${IMAGE_SOURCE}"
echo "Platforms:                ${PLATFORMS}"

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "DRY_RUN=1, not running docker buildx."
  exit 0
fi

if [[ "${SKIP_GHCR_AUTH_CHECK}" != "1" && ( "${PUSH}" == "1" || "${PUSH_EXISTING}" == "1" ) ]]; then
  auth_status="$(gh auth status 2>&1 || true)"
  if ! grep -q "write:packages" <<<"${auth_status}"; then
    echo "GitHub CLI auth is missing the write:packages scope." >&2
    echo "Run 'gh auth refresh -h github.com -s write:packages', then retry." >&2
    exit 1
  fi
  ghcr_user="${GHCR_USER:-${repo_slug%%/*}}"
  if [[ -z "${ghcr_user}" ]]; then
    ghcr_user="$(gh api user --jq .login)"
  fi
  gh auth token | docker login ghcr.io -u "${ghcr_user}" --password-stdin >/dev/null
fi

if [[ "${PUSH_EXISTING}" == "1" ]]; then
  docker image inspect "${target_image}" >/dev/null
  docker push "${target_image}"
  exit 0
fi

if [[ "${SKIP_UPSTREAM_CHECK}" != "1" ]]; then
  if ! docker manifest inspect "${upstream_image}" >/dev/null; then
    echo "Upstream runtime image was not found: ${upstream_image}" >&2
    echo "Set UPSTREAM_IMAGE to an existing Forgejo image you intentionally want to reuse." >&2
    exit 1
  fi
fi

docker buildx build \
  --platform "${PLATFORMS}" \
  --file "${DOCKERFILE}" \
  --build-arg "RELEASE_VERSION=${release_version}" \
  --build-arg "UPSTREAM_IMAGE=${upstream_image}" \
  --build-arg "UPSTREAM_VERSION=${upstream_version}" \
  --build-arg "PATCH_NAME=${PATCH_NAME}" \
  --build-arg "IMAGE_SOURCE=${IMAGE_SOURCE}" \
  --build-arg "GOPROXY=$(go env GOPROXY)" \
  --tag "${target_image}" \
  "${build_output[@]}" \
  "${FORGEJO_DIR}"

echo "Built ${target_image}"
if [[ "${PUSH}" != "1" ]]; then
  echo "Set PUSH=1 to publish it to the registry."
fi
