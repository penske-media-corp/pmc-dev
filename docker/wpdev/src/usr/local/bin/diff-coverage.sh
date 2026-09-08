#!/usr/bin/env bash
#
# diff-coverage.sh -- report which lines CHANGED on the current git branch (vs a
# base ref) are NOT covered by a plugin's PHPUnit suite ("diff coverage").
#
# Wraps phpunit (clover report) + diffFilter (exussum12/coverage-checker, shipped
# at /usr/bin/diffFilter). Xdebug already exposes coverage mode in this image.
#
# Only files the test run actually instrumented are evaluated: diffFilter skips
# any changed file absent from the coverage report (TS/CSS/JSON/templates, test
# files, and source that no executed test ever loads). Unchanged lines are never
# considered. So we never flag coverage gaps for code we did not touch -- but note
# the flip side: a changed source file that NO test even loads is silently ignored
# here (it won't appear in the coverage report), so this is not a substitute for
# "did I write any test at all for this file".
#
# Usage:
#   diff-coverage.sh [-d PLUGIN_DIR] [-b BASE] [-f FILTER] [-o OUTDIR] [PATH ...]
#
#   -d PLUGIN_DIR  plugin root to run phpunit from        (default: $PWD)
#   -b BASE        git base ref for the branch diff       (default: origin/main)
#   -f FILTER      phpunit --filter value (test class)    (default: full suite)
#   -o OUTDIR      dir for clover/diff/log artifacts       (default: a mktemp dir)
#   PATH ...       source paths RELATIVE TO PLUGIN_DIR to scope the diff to
#                  (default: the whole plugin dir; diffFilter narrows to files
#                   that were actually instrumented)
#
# Examples (run inside the wp container, e.g. via ./shell):
#   cd <plugin> && diff-coverage.sh                       # full suite, whole diff
#   diff-coverage.sh -f Test_Boomerang_Provider providers/boomerang.php
#   diff-coverage.sh -d /pmc-dev/wp-src/plugins/pmc-plugins/pmc-adm-v2 -b origin/main
#
# Exit: 0 = every changed (instrumented) line is covered;
#       non-zero = uncovered changed lines exist (listed above the summary).
set -o pipefail

PLUGIN_DIR="${PWD}"
BASE="origin/main"
FILTER=""
OUTDIR=""

usage() { sed -n '2,/^set -o/p' "$0" | sed 's/^# \{0,1\}//; $d'; exit "${1:-0}"; }

while getopts ":d:b:f:o:h" opt; do
  case "${opt}" in
    d) PLUGIN_DIR="${OPTARG}" ;;
    b) BASE="${OPTARG}" ;;
    f) FILTER="${OPTARG}" ;;
    o) OUTDIR="${OPTARG}" ;;
    h) usage 0 ;;
    :) echo "diff-coverage.sh: -${OPTARG} requires an argument" >&2; usage 2 ;;
    \?) echo "diff-coverage.sh: unknown option -${OPTARG}" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))
SCOPE=("$@")   # source paths relative to PLUGIN_DIR; empty => whole plugin

command -v phpunit   >/dev/null || { echo "phpunit not found on PATH" >&2; exit 3; }
command -v diffFilter >/dev/null || { echo "diffFilter not found on PATH" >&2; exit 3; }

[[ -d "${PLUGIN_DIR}" ]] || { echo "plugin dir not found: ${PLUGIN_DIR}" >&2; exit 3; }
OUTDIR="${OUTDIR:-$(mktemp -d "${TMPDIR:-/tmp}/diff-coverage.XXXXXX")}"
mkdir -p "${OUTDIR}"
CLOVER="${OUTDIR}/coverage-clover.xml"
DIFF="${OUTDIR}/branch.diff"
LOG="${OUTDIR}/phpunit.log"

# Resolve the plugin's git root (may sit above PLUGIN_DIR, e.g. a monorepo).
git config --global --add safe.directory '*' >/dev/null 2>&1 || true
GIT_ROOT="$(git -C "${PLUGIN_DIR}" rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "not inside a git repo: ${PLUGIN_DIR}" >&2; exit 3; }
git -C "${GIT_ROOT}" rev-parse --verify --quiet "${BASE}" >/dev/null \
  || { echo "base ref not found in ${GIT_ROOT}: ${BASE}" >&2; exit 3; }

REL_PLUGIN="${PLUGIN_DIR#"${GIT_ROOT}"/}"   # e.g. pmc-adm-v2
PATHSPECS=()
if [[ ${#SCOPE[@]} -eq 0 ]]; then
  PATHSPECS=("${REL_PLUGIN}")
else
  for p in "${SCOPE[@]}"; do PATHSPECS+=("${REL_PLUGIN}/${p}"); done
fi

echo "== plugin dir : ${PLUGIN_DIR}"
echo "== git root   : ${GIT_ROOT}"
echo "== base ref   : ${BASE}"
echo "== filter     : ${FILTER:-<full suite>}"
echo "== scope      : ${PATHSPECS[*]}  (relative to git root)"
echo "== artifacts  : ${OUTDIR}"

echo
echo "== 1/3 running phpunit with clover coverage ..."
( cd "${PLUGIN_DIR}" \
    && phpunit --coverage-clover "${CLOVER}" ${FILTER:+--filter "${FILTER}"} ) \
    > "${LOG}" 2>&1
PHPUNIT_CODE=$?
grep -E "PHPUnit [0-9]|Tests:|OK \(|FAILURES!|ERRORS!|Time:" "${LOG}" || true
echo "   phpunit exit=${PHPUNIT_CODE}; clover=${CLOVER}; full log=${LOG}"
[[ -s "${CLOVER}" ]] || { echo "ERROR: no clover coverage produced (see log)" >&2; exit 3; }

echo
echo "== 2/3 diffing ${BASE}...HEAD scoped to source ..."
git -C "${GIT_ROOT}" diff "${BASE}...HEAD" -- "${PATHSPECS[@]}" > "${DIFF}"
echo "   diff = ${DIFF} ($(wc -l < "${DIFF}") lines)"
[[ -s "${DIFF}" ]] || { echo "No changes in scope vs ${BASE}; nothing to check."; exit 0; }

echo
echo "== 3/3 diff coverage -- CHANGED lines with NO test coverage =="
diffFilter --clover "${DIFF}" "${CLOVER}"
DF_CODE=$?
echo
echo "diffFilter exit=${DF_CODE}  (0 => all changed instrumented lines covered)"
exit "${DF_CODE}"
