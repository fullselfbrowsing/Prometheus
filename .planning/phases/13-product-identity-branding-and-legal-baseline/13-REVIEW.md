---
phase: 13-product-identity-branding-and-legal-baseline
reviewed: 2026-06-24T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .planning/chromium/check-falkon-gpl-guard.sh
  - .planning/chromium/smoke-launch-prometheus.sh
  - .planning/chromium/check-chromium-env.sh
  - NOTICES.md
  - README.md
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-06-24
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the three executable gates plus the two legal-baseline content files at standard
depth, treating the `.planning/chromium/` shell scripts as production gates and `NOTICES.md`
/ `README.md` as shipped legal/marketing content.

The two intentional deviations called out as known/accepted were verified and are **not**
re-raised:

- **Env-gate ancestor acceptance** (`check-chromium-env.sh` lines 44-49) is correct. When the
  pinned baseline SHA is absent from history, `git merge-base --is-ancestor` returns rc=128
  (`fatal: Not a valid commit name`), the `|| fail` fires, and the gate fails closed. It does
  not silently pass on a detached or resynced checkout that lost the lineage. Verified
  empirically.
- **Smoke quit hardening** (`smoke-launch-prometheus.sh` lines 168-217) correctly handles the
  osascript-returns-0-without-delivery race: it re-verifies real process exit, escalates
  osascript → SIGTERM → SIGKILL with bounded waits, and only the SIGKILL-failure branch
  returns failure. The `$(())` counters and `pkill ... || true` guards do not trip `set -e`
  (verified).

The headline defect is a **latent BLOCKER**: the modified `check-chromium-env.sh` was relaxed
for git ancestry but still hard-requires the pre-branding `Chromium.app` binary, while
`smoke-launch-prometheus.sh` runs that gate as a mandatory preflight before launching the
rebranded `Prometheus.app`. The gate passes today only because both `Chromium.app` and
`Prometheus.app` coexist in the build dir — and the team itself documents the `Chromium.app`
as a "stale" leftover. A clean branded rebuild produces only `Prometheus.app`, at which point
the env gate fails and the Prometheus smoke can never run. The remaining findings are a
dangling legal-pointer in `NOTICES.md`, a loose identity assertion, an orphaned-helper gap in
the hardened quit path, and minor dead config.

The license naming in `NOTICES.md` and `README.md` is otherwise accurate: Chromium BSD-3-Clause,
Font Awesome (CC BY 4.0 + OFL 1.1 + MIT), Poppins OFL 1.1, Space Mono OFL 1.1, FSB-owned. The
`v1 GPLv3` licensing badge is explicitly scoped to the preserved Falkon v1 reference in the
README prose, so it is not a false claim about the v2 Chromium product.

## Critical Issues

### CR-01: Env gate hard-requires pre-branding `Chromium.app`; blocks the Prometheus smoke on any clean branded build

**File:** `.planning/chromium/check-chromium-env.sh:16,67,89-91`
(consumed by `.planning/chromium/smoke-launch-prometheus.sh:96`)

**Issue:**
`check-chromium-env.sh` was modified this phase to accept the pinned baseline as an *ancestor*
of HEAD so the branded branch passes the lineage check. But the same script still hardcodes the
pre-branding binary:

```bash
CHROMIUM_BIN="${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium"   # line 16
...
[ -x "${CHROMIUM_BIN}" ] || fail "missing executable Chromium binary ..."  # line 67
bin_file_output="$(file "${CHROMIUM_BIN}")" || fail ...                     # line 89
echo "${bin_file_output}" | grep -q 'arm64'  || fail ...                    # line 91
```

`smoke-launch-prometheus.sh:96` runs this gate as a mandatory preflight under `set -e`:

```bash
bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"
```

The entire point of Phase 13 branding is that `PRODUCT_FULLNAME=Prometheus` renames the bundle
to `Prometheus.app` (PRODUCT-IDENTITY-INVENTORY.md line 18; the smoke itself targets
`Prometheus.app/Contents/MacOS/Prometheus` and asserts `CFBundleName`/`CFBundleIdentifier`).
On a correctly branded **clean** build, `Chromium.app` does not exist, so `check-chromium-env.sh`
fails at line 67 and the Prometheus smoke aborts before it ever launches Prometheus.

This is currently masked only because the build dir holds BOTH bundles
(`out/Default/Chromium.app` and `out/Default/Prometheus.app` both present), and the team
classifies the `Chromium.app` as a "stale ... harmless build leftover." PRODUCT-IDENTITY-
INVENTORY.md line 30 confirms the intended end state is `Prometheus.app` only —
`Chromium.app` persisting is described as the *stale-cache failure mode*. So the gate that is
supposed to certify a clean branded environment passes only by relying on an artifact the
project considers stale. Any `gn clean` / fresh `out/` / CI-from-scratch branded build breaks
the gate and, transitively, the smoke.

**Fix:**
Make the env gate branding-aware so it accepts the rebranded binary (and ideally prefers it):

```bash
# Resolve the product binary: branded Prometheus.app if present, else baseline Chromium.app.
if [ -x "${BUILD_DIR}/Prometheus.app/Contents/MacOS/Prometheus" ]; then
  CHROMIUM_BIN="${BUILD_DIR}/Prometheus.app/Contents/MacOS/Prometheus"
elif [ -x "${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium" ]; then
  CHROMIUM_BIN="${BUILD_DIR}/Chromium.app/Contents/MacOS/Chromium"
else
  fail "no built product binary: expected ${BUILD_DIR}/Prometheus.app/.../Prometheus (branded) or ${BUILD_DIR}/Chromium.app/.../Chromium (baseline); rebuild after BRANDING patch (gn gen + autoninja)"
fi
```

The subsequent `[ -x ]`, `file`, `Mach-O`, and `arm64` checks then operate on the resolved
`CHROMIUM_BIN` unchanged. This keeps Phase-12 (unmodified) callers working while unblocking the
Phase-13 branded smoke on a clean build.

## Warnings

### WR-01: NOTICES.md points to license files that do not exist (`LICENSES/poppins-OFL.txt`, `LICENSES/spacemono-OFL.txt`)

**File:** `NOTICES.md:25,31`

**Issue:**
`NOTICES.md` is a release-shipped legal file (LEGAL-NOTICE-INVENTORY.md line 58: "must be
included in any release artifact"). It directs the reader to full license texts:

```
25: License: SIL Open Font License 1.1 — see LICENSES/poppins-OFL.txt
31: License: SIL Open Font License 1.1 — see LICENSES/spacemono-OFL.txt
```

Neither file exists; the `LICENSES/` directory is absent from the repo and from git
(`git ls-files | grep LICENSES` is empty; no `*OFL*` file anywhere outside `.context/`).
LEGAL-NOTICE-INVENTORY.md lines 32-33 explicitly mark both as "Placeholder — Phase 14 drops
... this license text." So the notices file presents Phase-14-deferred artifacts as if already
present, producing dangling pointers in the legal surface. The OFL 1.1 requires the full
license text to accompany distributed fonts; a "see LICENSES/poppins-OFL.txt" that resolves to
nothing is a concrete legal-baseline correctness gap if NOTICES.md ships before Phase 14.

**Fix:**
Until the license texts land in Phase 14, do not imply the files exist. Either inline the
canonical URL, or mark the local path as pending:

```
License: SIL Open Font License 1.1 — https://scripts.sil.org/OFL
(full local text added with the font files in a later phase)
```

Alternatively, commit the two OFL text files now (the OFL 1.1 body is identical for both
faces) so the existing pointers resolve.

### WR-02: Prometheus identity assertion is a loose substring grep, not a CFBundleName check

**File:** `.planning/chromium/smoke-launch-prometheus.sh:354-355`

**Issue:**

```bash
plutil -p "${PLIST}" | grep -q 'Prometheus' \
  || fail "CFBundleName does not contain 'Prometheus' in ${PLIST}"
```

`plutil -p` dumps the entire Info.plist. `grep -q 'Prometheus'` matches if *any* field contains
the string — in the real plist that is `CFBundleDisplayName`, `CFBundleExecutable`, AND
`CFBundleName` (verified). The failure message claims this verifies `CFBundleName`, but a build
where, say, `CFBundleExecutable=Prometheus` while `CFBundleName` regressed to `Chromium` (a
plausible partial-branding drift) would still pass. The companion bundle-id check on line 357
(`grep -q 'com\.fullselfbrowsing\.prometheus'`) is correctly specific; the name check should be
too, especially since BRAND-06 is about the user-visible product name.

**Fix:**
Use `plutil -extract` to assert the specific key:

```bash
name="$(plutil -extract CFBundleName raw -o - "${PLIST}" 2>/dev/null)" \
  || fail "CFBundleName missing from ${PLIST}"
[ "${name}" = "Prometheus" ] \
  || fail "CFBundleName is '${name}', expected 'Prometheus' in ${PLIST}"

bid="$(plutil -extract CFBundleIdentifier raw -o - "${PLIST}" 2>/dev/null)" \
  || fail "CFBundleIdentifier missing from ${PLIST}"
[ "${bid}" = "com.fullselfbrowsing.prometheus" ] \
  || fail "CFBundleIdentifier is '${bid}', expected 'com.fullselfbrowsing.prometheus'"
```

### WR-03: Hardened quit path can leave orphaned `Prometheus Helper` children while still reporting status=0

**File:** `.planning/chromium/smoke-launch-prometheus.sh:177,190-192,201-217`

**Issue:**
The exit-detection throughout the quit/kill path checks and signals only the launched parent
PID (`_attempt_pid`) and its *direct* children via `pkill -P "${_attempt_pid}"`:

```bash
pkill -TERM -P "${_attempt_pid}" 2>/dev/null || true   # direct children only
kill "${_attempt_pid}" 2>/dev/null || true             # parent only
...
while kill -0 "${_attempt_pid}" 2>/dev/null && [ "${elapsed}" -lt ... ]; do   # parent only
```

On macOS the `Prometheus Helper (Renderer/GPU/Network/Alerts)` processes are frequently *not*
direct children of the main browser process, and any helper that outlives the parent is
reparented to launchd. Once the parent PID is gone, `kill -0 "${_attempt_pid}"` reports the
process as terminated and the function returns `_attempt_status=0` (line 219) — even though
helper processes may still be running and still holding the temp profile dir. The cleanup trap
(lines 80-89) has the same parent-direct-children-only limitation, so the EXIT path does not
reliably reap them either. Net effect: a "passing" smoke can leak `Prometheus Helper*`
processes. This is inherited from `smoke-launch-unmodified.sh`, but the Prometheus quit path was
explicitly hardened and is in scope for this review.

**Fix:**
Reap the whole bundle's process set by executable path, not just the direct-child tree, after
the parent exits — e.g.:

```bash
# After parent confirmed gone, sweep any surviving helpers for THIS bundle.
pkill -KILL -f "${BUILD_DIR}/Prometheus.app/Contents/Frameworks/.*Prometheus Helper" 2>/dev/null || true
```

(Scope the pattern to `${BUILD_DIR}` so it never touches an unrelated installed Prometheus.)
At minimum, document that orphaned helpers are not detected so a green smoke is not mistaken
for a fully-reaped run.

### WR-04: `gn_args` evidence capture is not error-guarded, unlike the adjacent revision capture

**File:** `.planning/chromium/smoke-launch-prometheus.sh:114`

**Issue:**

```bash
chromium_revision="$(git -C "${CHROMIUM_SRC}" rev-parse HEAD 2>/dev/null)" \
  || fail "could not read Chromium HEAD from ${CHROMIUM_SRC}"     # guarded

gn_args="$(tr '\n' ' ' < "${BUILD_DIR}/args.gn" 2>/dev/null | sed 's/[[:space:]]*$//')"  # NOT guarded
```

If `${BUILD_DIR}/args.gn` is unreadable, the `2>/dev/null` swallows the error and `gn_args`
becomes the empty string, which is then written verbatim into the status file as
`gn_args=`. The smoke proceeds as if the build environment were fine and records misleading
evidence. The env-gate preflight does require `args.gn` to be readable, so the practical window
is narrow (a race or a gate bypass), but the inconsistency with the guarded `chromium_revision`
capture two lines above is a latent evidence-integrity gap. Note the unmodified reference also
captures `depot_tools_revision` with a `|| fail` guard that the Prometheus variant dropped
entirely (line 110-111 in the reference has no counterpart here) — acceptable since the field
was intentionally removed, but worth confirming that drop was deliberate.

**Fix:**
Guard the read so a missing/unreadable `args.gn` fails loudly or records an explicit sentinel:

```bash
if ! gn_args="$(tr '\n' ' ' < "${BUILD_DIR}/args.gn" 2>/dev/null | sed 's/[[:space:]]*$//')"; then
  fail "could not read ${BUILD_DIR}/args.gn for evidence"
fi
```

## Info

### IN-01: GPL guard sets depot_tools / build-dir config it never uses

**File:** `.planning/chromium/check-falkon-gpl-guard.sh:14-20`

**Issue:**
The guard copies the Phase-12 gate preamble wholesale:

```bash
DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"
export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
```

None of `DEPOT_TOOLS`, `CHROMIUM_ROOT`, `BUILD_DIR`, the `PATH` export, or `DEVELOPER_DIR` is
used anywhere in the script — it only greps `${CHROMIUM_SRC}/chrome/browser/prometheus` and
`${CHROMIUM_SRC}/components/prometheus`. This is harmless dead config but invites confusion
(e.g., a reader assuming the guard scans `BUILD_DIR`).

**Fix:** Drop the unused assignments and exports; keep only `SCRIPT_DIR`, `PROJECT_ROOT`,
`CHROMIUM_ROOT`/`CHROMIUM_SRC` (the latter is used), and `SRC`.

### IN-02: GPL guard patterns are broad enough to false-positive on legitimate Chromium code

**File:** `.planning/chromium/check-falkon-gpl-guard.sh:36-46`

**Issue:**
Patterns such as `QWebEngineView`, `#include.*WebPage.h`, and `#include.*tabwidget` are generic
Qt/UI names, not uniquely Falkon. If any non-Falkon-derived file with one of these strings is
ever added under `chrome/browser/prometheus` or `components/prometheus`, the guard fails closed
(blocks the commit) even with no actual GPL contamination. Risk is currently low because the
scan scope is narrowed to two Prometheus-owned dirs that hold no C++ yet, and the file already
documents this as `[ASSUMED: A1]` with the exhaustive sweep deferred to Phase 23.

**Fix:** No change required for Phase 13. When Phase 23 produces the authoritative Falkon
signature spec, tighten these to Falkon-specific tokens (e.g., the `qzcommon.h` /
`QzBrowserWindow` / `Falkon::` markers) and drop the bare-Qt patterns, or pair them with a
Falkon-provenance check to avoid blocking legitimate Chromium-native UI code.

---

_Reviewed: 2026-06-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
