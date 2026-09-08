# CLAUDE.md — pmc-dev

Local WordPress/VIP development environment (Docker + Vagrant). WordPress source
lives under `wp-src/` and is mounted into the `wp` container. This repo is
**public open source — never commit secrets.** Only commit tracked/modified
files; never `git add .`/`-A`.

## Running commands in the container — `./shell`

`./shell` runs a command inside the `wp` container. Read the script: it takes
**one** argument and runs `docker compose exec wp env --chdir=/pmc-dev/wp-src -S "$CMD"`.

- **`env -S` splits the single string into args** (it honors nested quotes) and
  execs the first token — it is **not** a shell. So shell syntax (`cd … && x`,
  pipes, `&&`) must be wrapped in `bash -c '…'`.
- **`env -S` mangles backslash escapes** (`\x27`, `\$`, `\n` → errors/mangling).
  For anything with escaping, write a script file under `tmp/` (mounted at
  `/pmc-dev/tmp`) and run `./shell "bash /pmc-dev/tmp/foo.sh"` instead.
- Default working dir is `/pmc-dev/wp-src`.
- **Run `./shell` from the repo root** (`~/src/pmc-dev`); it's a relative path.

### Path mapping (host ⇄ container)

Host `~/src/pmc-dev/wp-src/…` ⇄ container `/pmc-dev/wp-src/…`. Build the
container path by swapping the host prefix `~/src/pmc-dev` for `/pmc-dev`.
Example: host `wp-src/plugins/pmc-plugins/pmc-adm-v2` →
container `/pmc-dev/wp-src/plugins/pmc-plugins/pmc-adm-v2`.

## Running PHPUnit

PHPUnit **9.6.x** is installed globally in the image at `/usr/share/php/phpunit`
(`phpunit` on PATH). The container-wide `phpunit` is shared by all 200+ plugins
and driven by the WordPress test library + `pmc-unit-test` bootstrap. Tests must
run **from the plugin directory** (bootstrap loads WP + the plugin).

```bash
# Full suite for a plugin (from repo root)
./shell "bash -c 'cd /pmc-dev/wp-src/plugins/pmc-plugins/pmc-adm-v2 && phpunit --no-coverage'"

# One test file BY PATH — the preferred single-test run. Works because the loader
# patch below (baked into the image) maps hyphenated filenames to underscore class
# names. Requires the rebuilt image; on an image built before the patch it fails.
./shell "bash -c 'cd <container-plugin-dir> && phpunit --no-coverage tests/test-class-pmc-ads.php'"

# FALLBACK — if the path run fails with "Class ... could not be found" (e.g. the
# image predates the patch), filter on the CLASS name instead (see caveat below)
./shell "bash -c 'cd <container-plugin-dir> && phpunit --no-coverage --filter Test_Class_PMC_Ads'"
```

- **Run by file path first; fall back to `--filter <Class>`.** With the loader
  patch baked in, running a single test file by path is the primary way. If it
  errors with **"Class … could not be found"** (typically because the running
  image predates the patch, or the target file was renamed), switch to
  `--filter <Class>` on the underscore class name — it doesn't depend on the patch.
- **`--no-coverage`** skips the `coverage-text` report many `phpunit.xml`s write
  to stdout (needs Xdebug/PCOV, adds noise). Drop it when you want coverage.
- Output is buried in PHP deprecation/notice noise; capture to a `tmp/*.log` and
  `grep -E "PHPUnit [0-9]|Tests:|OK \(|FAILURES|ERRORS|Time:"`.
- **`--filter <Class>` vs path differ**: a path loads only the classes declared
  in that file; `--filter` is a name-regex across the whole discovered suite, so
  counts can differ (e.g. adm-v2 `Test_Class_PMC_Ads`: 108 via filter, 77 by path).
- **Order-dependent failures**: in pmc-adm-v2, `test_disable_ad_during_livestream_option`
  and `test_filter_pmc_pre_render_ads` pass in isolation but fail in the full
  suite — cross-test state pollution from other classes, not real defects.
  (Not yet fixed — revisit.) Boomerang's `test_wp_enqueue_scripts_concert_platform`
  behaves the same way (flaky/state-sensitive: fails under a plain `--filter` run
  but passes under `--coverage-clover`).

## Diff coverage — `diff-coverage.sh`

Answers "do the lines I changed on this branch have test coverage?" — as opposed
to whole-file coverage. Baked into the image at `/usr/local/bin/diff-coverage.sh`
(on PATH; source is `docker/wpdev/src/usr/local/bin/diff-coverage.sh`). It wraps
`phpunit --coverage-clover` + `diffFilter` (exussum12/coverage-checker, at
`/usr/bin/diffFilter`); Xdebug already exposes `coverage` mode.

```bash
# Full-suite diff coverage for whatever changed under the plugin (from repo root)
./shell "bash -c 'cd <container-plugin-dir> && diff-coverage.sh'"

# Fast single-file loop: filter to one class, scope the diff to one source file
./shell "bash -c 'cd <container-plugin-dir> && diff-coverage.sh -f Test_Boomerang_Provider providers/boomerang.php'"
```

- Flags: `-d PLUGIN_DIR` (default `$PWD`), `-b BASE` (default `origin/main`),
  `-f FILTER` (default full suite), `-o OUTDIR` (default a `mktemp` dir under
  `/tmp` — decoupled from the `/pmc-dev` mount); trailing args are source paths
  relative to `PLUGIN_DIR`. `-h` prints full usage.
- **Auto-detects the plugin's git root**, so it works for the nested
  `wp-src/plugins/pmc-plugins` repo (whose branches diff against `origin/main`;
  its `master` is a stale 4485-commit legacy branch — don't use it as the base).
- **`diffFilter` only evaluates files present in the clover report.** Changed
  files no executed test loaded (TS/CSS/JSON/templates, test files, uncovered
  source) are silently skipped — so untouched/irrelevant code is never flagged.
  Flip side: a changed source file that *no* test even loads won't appear at all,
  so this is not a check for "did I write any test for this file".
- Exit code: `0` = every changed instrumented line is covered; non-zero = gaps
  (listed above the summary, with a `%` total).
- **Requires a rebuild to land on PATH** (`docker compose build wp` / `./build`).
  Until then, invoke it by its mounted source path:
  `bash /pmc-dev/docker/wpdev/src/usr/local/bin/diff-coverage.sh …`. No Dockerfile
  change is needed — `ADD src/ /build/` + the existing `chmod` on
  `/build/usr/local/bin/*` bake it in and make it executable.

## PHPUnit "run by file path" — the hyphen/underscore patch

**Problem:** WordPress/PMC name test files with hyphens (`test-class-foo.php`) but
name classes with underscores (`Test_Class_Foo`). PHPUnit 9's
`StandardTestSuiteLoader::load()` derives the class from the filename basename and
its fallback only bridges `\`/`_` separators (`stripos … '_'.$name`), so a
hyphen never matches an underscore →
`phpunit tests/test-class-foo.php` fails with **"Class … could not be found"**.
(Directory/`<testsuite>` scanning uses the lenient `TestSuite::addTestFile()`
which runs *all* TestCase subclasses regardless of name — that's why the full
suite works.)

**Fix (build-time patch, so it survives image rebuilds):** normalize `-`→`_` in
the derived name. Files (the patch tooling lives in the build context under
`docker/wpdev/patches/` and is **not** shipped in the final image — only the
patched output file is):
- `docker/wpdev/patches/phpunit9-standard-testsuite-loader.patch` — one-line diff:
  `$suiteClassName = str_replace('-', '_', basename($suiteClassFile, '.php'));`
- `docker/wpdev/patches/apply-patches.sh` — applies it at build time; idempotent
  (skips if already patched) and **fails the build loudly** if the target file
  changes so the patch no longer applies.
- `docker/wpdev/Dockerfile` — added `patch` to apt. In the **`build`** stage:
  `COPY patches/ /tmp/patches/` (a throwaway dir, NOT under `/build`, so the tooling
  never ships), then `RUN bash /tmp/patches/apply-patches.sh` patches the phpunit
  inherited from base at `/usr/share/php/phpunit`, then
  `install -D -m 0644 …StandardTestSuiteLoader.php /build/usr/share/php/…` copies the
  patched file into `/build` and `rm -rf /tmp/patches`. **Installing the patched
  file into `/build` is essential:** the final image is `FROM base` and
  `COPY --from=build /build/ /` only overlays `/build`, so a patch applied to the
  build stage's phpunit would otherwise be discarded — the copied file is what makes
  it reach the shipped image. (Do NOT re-add a `COPY patches/` + patch step to the
  `base` stage, and do NOT put the patch tooling under `src/`; both were tried and
  removed.)

**Status / to activate:** verified working (applies cleanly, idempotent, path
runs return OK). **Requires a rebuild to bake in:** `docker compose build wp`
(or `./build`). Not yet built or committed as of 2026-08-31 — new files are
untracked, Dockerfile + CLAUDE.md modified; the running container was live-patched
ephemerally during testing.

**Do NOT "fix" this by upgrading PHPUnit.** Verified against 10.5/11.5 source:
the strict `StandardTestSuiteLoader` is gone but the replacement `TestSuiteLoader`
still requires `str_ends_with(strtolower(shortName), strtolower(filenameBase))`
— hyphens still fail — AND that loader is now used for directory scanning too, so
the whole hyphenated suite would silently skip (0 tests + warnings) unless files
are renamed. Plus 10/11 are breaking, container-wide migrations (XML schema
overhaul: `<filter>/<whitelist>`, `convert*ToExceptions`, `coverage-text` all
removed; static-only data providers; `TestListener`→events; PHP 8.1/8.2+).
The wrapper/patch stays on 9.x.

## Docker build wiring

- `docker-compose.yml` → symlink to `docker-compose.revtech.yml`. The `wp`
  service builds from context `./docker/wpdev`; repo is mounted at `/pmc-dev`,
  `wp-root` at `/var/www/html`.
- `docker/wpdev/Dockerfile` is 3-stage: `base` (apt, php 8.4, composer, phpunit,
  phpcs) → `build` (WP core, wp-tests, plugins) → final `FROM base` +
  `COPY --from=build /build/`. Bake image-wide tooling changes into **base**.
- `./build` = `docker compose build --ssh default`.
