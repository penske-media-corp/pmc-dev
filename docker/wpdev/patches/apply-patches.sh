#!/usr/bin/env bash
#
# Apply local source patches to third-party packages baked into the Docker image
# (see docker/wpdev/Dockerfile). Runs at image build time, in the `build` stage;
# the patched files are then staged under /build so the final `FROM base` image
# picks them up via COPY --from=build.
#
# Design goals:
#   - Idempotent: a target already carrying the verify marker is left untouched,
#     so re-running (or a re-applied layer) is a no-op.
#   - Fail loud: if a patch cannot be applied and the marker is still absent,
#     the build aborts (non-zero exit) so we never ship a silently-unpatched
#     image -- e.g. when a PHPUnit point release changes the patched file.
#
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# apply <target-file> <patch-file> <verify-marker>
apply() {
  local target="$1" patch="$2" marker="$3"

  if [[ ! -f "${target}" ]]; then
    echo "patches: SKIP (target missing): ${target}" >&2
    return 0
  fi

  if grep -qF -- "${marker}" "${target}"; then
    echo "patches: OK (already applied): ${target}"
    return 0
  fi

  echo "patches: applying ${patch} -> ${target}"
  patch --forward "${target}" < "${PATCH_DIR}/${patch}"

  if ! grep -qF -- "${marker}" "${target}"; then
    echo "patches: FAILED to apply ${patch} to ${target}" >&2
    exit 1
  fi
  echo "patches: applied ${patch}"
}

# PHPUnit 9 -- run WordPress-style hyphenated test files by path.
apply \
  "/usr/share/php/phpunit/vendor/phpunit/phpunit/src/Runner/StandardTestSuiteLoader.php" \
  "phpunit9-standard-testsuite-loader.patch" \
  "str_replace('-', '_', basename(\$suiteClassFile, '.php'))"

echo "patches: done"
