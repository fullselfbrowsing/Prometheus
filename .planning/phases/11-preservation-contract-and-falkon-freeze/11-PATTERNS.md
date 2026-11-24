# Phase 11: Preservation Contract and Falkon Freeze - Pattern Map

**Mapped:** 2026-06-23
**Files analyzed:** 5 new/modified files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | config | transform, file-I/O | `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`; `08/09/10-VERIFICATION.md` | exact |
| `.planning/preservation/verify-preservation.sh` | utility | batch, file-I/O | `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-PATTERNS.md` shell-gate pattern; `11-RESEARCH.md` preservation command skeleton | role-match |
| `README.md` | config | transform | `.planning/PROJECT.md`; `.planning/ROADMAP.md`; stale sections in `README.md` | role-match |
| `.planning/STATE.md` | store | transform | `.planning/STATE.md` frontmatter, Current Position, Deferred Items | exact |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | config | transform | `.planning/chromium/CHROMIUM-CHECKOUT.md` handoff sections | exact |

## Pattern Assignments

### `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` (config, transform/file-I/O)

**Analog:** `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`

**Existing header and decision pattern** (lines 1-11):
```markdown
# Falkon to Chromium Preservation Dossier

**Created:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Purpose:** Preserve the product intent, design language, shipped v1 behavior, source reference, and asset inventory before retiring the Falkon/QtWebEngine implementation.

## Executive Decision

Falkon was a useful bootstrap shell, but it is no longer the right production base.
```

Keep this file as the single canonical dossier. Do not split the migration map, visual-check ledger, or wipe checklist into a new preservation document. Context locks that decision in `11-CONTEXT.md` lines 20-22 and line 40.

**Preservation evidence pattern** (current source-state section, lines 26-51; update in place):
```markdown
| Item | Value |
|------|-------|
| Nested repo path | `falkon/` |
| Preserved HEAD | `b0521c9d37e7545c680b78dfcc24f777a984091c` |
| Local bundle | `.context/falkon-preservation/falkon-prometheus-v1.bundle` |
| Patch series | `.context/falkon-preservation/patches/` |
```

Add a reproducible evidence block using the command pattern from `11-RESEARCH.md` lines 194-203:
```bash
git bundle verify .context/falkon-preservation/falkon-prometheus-v1.bundle
git ls-remote .context/falkon-preservation/falkon-prometheus-v1.bundle HEAD refs/heads/master refs/remotes/origin/master
find .context/falkon-preservation/patches -maxdepth 1 -name '*.patch' | wc -l

tmpdir=$(mktemp -d .context/falkon-preservation/restore-check-XXXXXX)
git clone .context/falkon-preservation/falkon-prometheus-v1.bundle "$tmpdir/repo"
git -C "$tmpdir/repo" rev-parse HEAD
rm -rf "$tmpdir"
```

The expected values are preserved HEAD `b0521c9d37e7545c680b78dfcc24f777a984091c`, patch count `81`, active `falkon/` absent, bundle path ignored under `.context/`, no active `screen` socket, status file `0`, and build log ending with "The build has finished successfully."

**License boundary pattern** (lines 53-80):
```markdown
Preserve these from Falkon as **reference material**:

- behavior contracts
- UI layouts
- design tokens
- asset lists
- test intent
- tool names and protocol shapes
- validation scripts and parity categories

Do not copy these without explicit license review:

- Falkon C++ implementation files
- Qt widget classes
- QSS files if treated as source derivative instead of design-token reference
- Falkon packaging scripts
- inherited Falkon/KDE/Qt-specific metadata
```

Every new migration row should carry a `License / Attribution Note` field. Use `contract_only`, `product_owned`, `third_party_attribution_required`, or `license_review_required`; do not leave this implied. Context lines 29-32 lock the strict default.

**Inventory table pattern** (lines 133-190):
```markdown
| Path | Role |
|------|------|
| `assets/prometheus.svg` | Product mark for README and external docs |
| `.planning/design/prometheus-browser/prometheus/styles.css` | canonical token source |
| `falkon/src/lib/data/icons/fa/*.svg` | Font Awesome Free SVG subset |
```

Reuse this compact two-column inventory shape for preserved artifacts, but add status where Phase 11 needs freeze/wipe semantics:
```markdown
| Item | Status | Evidence / Rule |
|------|--------|-----------------|
| `falkon/` | already_removed | Active checkout absent; restore only from bundle |
| `.context/falkon-preservation/` | must_stay | Bundle plus 81 patches |
| Falkon C++/QSS/package scripts | reference_only | Do not copy into Chromium without review |
| Chromium assets/resources | future_chromium_owned | Reimplement through Chromium resource pipeline |
```

**Capability migration map pattern** (existing behavior sections, lines 191-287; normalized row shape from `11-RESEARCH.md` lines 215-218):
```markdown
| Capability | v1 Behavior Contract | Falkon Reference | Chromium Owner | Parity Evidence | License / Attribution Note |
|------------|----------------------|------------------|----------------|-----------------|----------------------------|
| Start page Ask FSB handoff | Prompt seeds FSB Agent composer without auto-submit | `start.html`, `prometheusstartbridge.*`, patches 0066-0071 | Phase 16 WebUI | Future WebUI/browser test plus manual UAT | Contract portable; QWebChannel/C++ implementation reference-only |
```

Owner mapping should copy phase ownership from `.planning/ROADMAP.md` lines 14-27:
```markdown
- Phase 14: Asset and Design System Port
- Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model
- Phase 16: Prometheus WebUI Surfaces and New Tab
- Phase 17: Native Agent Command Service and Tab Ownership
- Phase 18: Page Adapter, DOM Snapshot, and Action Verification
- Phase 19: MCP Bridge and Multi-Agent Runtime Compatibility
- Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel
- Phase 21: Supervision, Pairing, and Remote Control
- Phase 23: Migration Parity, Security Hardening, and De-Falkon Gate
- Phase 24: Packaging, Release Validation, and Handoff
```

**Chromium target layout pattern** (lines 297-313):
```markdown
| Target area | Suggested location |
|-------------|--------------------|
| Browser-process agent service | `chrome/browser/prometheus/agent/` |
| Side panel WebUI resources | `chrome/browser/resources/prometheus_side_panel/` |
| WebUI controllers | `chrome/browser/ui/webui/prometheus/` |
| Theme/assets | Chromium resource packs, `grit`, `.pak`, and license metadata |
```

Keep target locations as future-owner guidance only. Do not make Phase 11 implement Chromium source work.

**Wipe checklist pattern** (lines 314-331, expand with statuses):
```markdown
Remove from the active source tree:

- `falkon/` source checkout.
- Falkon build artifacts under `falkon/build/`.
- Qt/Falkon-specific package scripts as active release machinery.

Do **not** remove:

- `.planning/`
- `.planning/design/`
- `.planning/preservation/`
- `.context/falkon-preservation/`
- root `assets/`
```

**Migration readiness rule** (lines 333-343):
```markdown
1. What v1 behavior is being preserved?
2. Which Falkon file is only a reference?
3. Which Chromium subsystem owns the new implementation?
4. What is the test that proves parity?
5. What legal/license notice is required?
```

Use these five questions as a dossier invariant. Every capability row must answer all five.

**Deferred visual-check ledger pattern** (source reports: `08-VERIFICATION.md` lines 1-38 and 192-255; `09-VERIFICATION.md` lines 1-36 and 168-208; `10-VERIFICATION.md` lines 1-32 and 145-195):
```markdown
| ID | Original Phase | Original Check | Chromium Owner | Status | Rationale / Future Evidence |
|----|----------------|----------------|----------------|--------|-----------------------------|
| VIS-09-05 | 09 | Toolbar icons are bundled FA vector glyphs | Phase 14 Asset and Design System Port | carry_forward | Re-run after Chromium resource packaging; preserve FA attribution comments |
```

Status values should be `carry_forward` or `retired`. A `retired` row must name the removed Falkon-only surface and the later Chromium phase that supersedes or intentionally drops it. Context lines 34-37 require all 26 checks to be mapped.

### `.planning/preservation/verify-preservation.sh` (utility, batch/file-I/O)

**Analog:** `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-PATTERNS.md`

This file is implied by `11-RESEARCH.md` lines 430-433 as an optional shell-based preservation gate. If the planner chooses documented commands instead, keep the same checks in the dossier and skip the script file.

**Shell header and argument pattern** (Phase 08 pattern map lines 400-427):
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
```

For Phase 11, `SOURCE_ROOT` should resolve from `.planning/preservation/` back to the workspace root.

**Static check helper pattern** (Phase 08 pattern map lines 431-445 and 617-626):
```bash
require_rg() {
  local pattern="$1"
  shift
  if ! rg --quiet "$pattern" "$@"; then
    printf 'Missing required pattern %s in %s\n' "$pattern" "$*" >&2
    exit 1
  fi
}
```

Use `require_rg` for dossier invariants such as `Chromium Owner`, `License / Attribution`, `carry_forward`, `retired`, `VIS-08`, `VIS-09`, `VIS-10`, `already_removed`, `must_stay`, and `reference_only`.

**Core preservation checks** (from `11-RESEARCH.md` lines 194-203 and 341-345):
```bash
bundle=".context/falkon-preservation/falkon-prometheus-v1.bundle"
patch_dir=".context/falkon-preservation/patches"
expected_head="b0521c9d37e7545c680b78dfcc24f777a984091c"

git bundle verify "$bundle"
head_ref="$(git ls-remote "$bundle" HEAD | awk '{print $1}')"
test "$head_ref" = "$expected_head"

patch_count="$(find "$patch_dir" -maxdepth 1 -name '*.patch' | wc -l | tr -d ' ')"
test "$patch_count" = "81"

tmpdir="$(mktemp -d .context/falkon-preservation/restore-check-XXXXXX)"
git clone "$bundle" "$tmpdir/repo"
restored_head="$(git -C "$tmpdir/repo" rev-parse HEAD)"
rm -rf "$tmpdir"
test "$restored_head" = "$expected_head"
```

Add `trap 'rm -rf "$tmpdir"' EXIT` if the script stores `tmpdir` outside a tight block. Do not leave a long-lived `falkon/` or restore clone behind; context lines 20-22 require temporary or reference-only restore checks.

**Stale state audit pattern** (from `11-RESEARCH.md` lines 362-367):
```bash
rg -n 'falkon/|QtWebEngine|detached.*screen|prometheus-chromium-build|chromium-build-screen|build is running' README.md .planning
screen -ls || true
test -f .context/chromium-build-screen.status && cat .context/chromium-build-screen.status
test -f .context/chromium-build-screen.log && tail -40 .context/chromium-build-screen.log
```

Treat stale references differently from allowed reference-only paths. The script should fail on false active-source or active-build claims, but not on the preservation dossier listing Falkon source paths as reference material.

**Validation command pattern** (from `11-RESEARCH.md` lines 430-433):
```bash
git diff --check
bash .planning/preservation/verify-preservation.sh
```

### `README.md` (config, transform)

**Analogs:** `.planning/PROJECT.md` current-state language and `.planning/ROADMAP.md` v2 thesis.

**Current project-language pattern** (`.planning/PROJECT.md` lines 3-6 and 19-23):
```markdown
Prometheus is an agent-native desktop browser, branded as **Prometheus** with the affiliation/tagline **Powered by FSB**. v1.0 proved the product shape on a Falkon/QtWebEngine fork, but the project is now migrating to Chromium as the production browser base.

**Active: v2.0 Chromium Engine Migration (started 2026-06-17).** Falkon is now treated as a preserved reference, not the production base.
```

**Roadmap thesis pattern** (`.planning/ROADMAP.md` lines 8-10):
```markdown
Prometheus keeps its product, design, and agent-native control thesis, but retires Falkon/QtWebEngine as the production base. v2.0 starts by preserving the v1 source reference and design/behavior decisions, then removes the active Falkon tree, checks out Chromium, establishes a reproducible Chromium baseline, and rebuilds Prometheus on Chromium-native primitives.
```

**Stale README sections to reconcile** (current `README.md` lines 17, 44, 206-220, 238-253):
```markdown
![Qt 6](https://img.shields.io/badge/Qt_6-QtWebEngine-41CD52?style=for-the-badge&logo=qt&logoColor=white)

Prometheus is an agent native desktop browser built on Qt and QtWebEngine.

Prometheus builds from the Qt and QtWebEngine source under `falkon/` with CMake.
cmake -S falkon -B falkon/build -DCMAKE_BUILD_TYPE=Release
falkon/tools/fsb-baseline/release-validate.sh

| `falkon/src/lib/agent/agentcommandrouter.*` | Native JSON command router... |
```

Phase 11 should at minimum remove or clearly label false active-source/build instructions. It can leave deeper product-doc rewrite to Phase 13 if it records that ownership. Research lines 394-397 recommend this split.

### `.planning/STATE.md` (store, transform)

**Analog:** `.planning/STATE.md`

**Frontmatter and Current Position pattern** (lines 1-8 and 25-30):
```yaml
status: Chromium source fetched; Xcode/Metal toolchain fixed; GN generation succeeded; first `chrome` build running in detached `screen`
last_activity: 2026-06-17 - verified Falkon bundle restore, removed active `falkon/`, installed depot_tools...
```

Update the same fields in place rather than adding a second state block. The new state must reconcile context line 42: no active `screen`, `.context/chromium-build-screen.status` is `0`, and `.context/chromium-build-screen.log` says the build finished successfully.

**Decision log pattern** (lines 135-144):
```markdown
- [Milestone v2.0]: Active `falkon/` checkout was removed after bundle restore verification. Root git status is clean after removal.
- [Milestone v2.0]: First Chromium `chrome` build is running in detached `screen` session `prometheus-chromium-build`; log `.context/chromium-build-screen.log`, status file `.context/chromium-build-screen.status`, working directory `.context/chromium/src`.
```

Replace only the stale build-session claim. Preserve the useful paths and prior evidence. A good new bullet shape is: build screen has exited, status file is `0`, no `screen` sockets were found, log says build finished successfully, launch remains Phase 12 scope.

**Deferred Items pattern** (lines 178-192):
```markdown
| verification | 08-VERIFICATION.md - 10 control-panel/side-panel visual checks | human_needed | v1.0 close 2026-06-17 |
| local_build | First Chromium `chrome` build must finish and launch before Prometheus patches begin | running | v2.0 Phase 12 2026-06-17 |
```

Keep the three human-needed rows as carried obligations until the dossier maps all 26 checks. Change `local_build` from `running` to a state that reflects build complete but unmodified Chromium launch still pending/Phase 12.

### `.planning/chromium/CHROMIUM-CHECKOUT.md` (config, transform)

**Analog:** `.planning/chromium/CHROMIUM-CHECKOUT.md`

**Status line pattern** (line 5):
```markdown
**Status:** Chromium source checkout complete; Xcode/Metal toolchain fixed; GN generation complete; first `chrome` build running in detached `screen` session.
```

Update this single-line summary first so readers do not miss the corrected state.

**Preservation handoff pattern to keep** (lines 21-27):
```markdown
### Falkon retirement gate

- Verified the Falkon preservation bundle.
- Restored the bundle into a temporary clone and confirmed the restored HEAD matched `b0521c9d37e7545c680b78dfcc24f777a984091c`.
- Removed the active `falkon/` checkout from the workspace.
- Kept the bundle and 81 patch files in `.context/falkon-preservation/`.
```

This section already matches Phase 11 preservation expectations. Do not weaken it.

**Stale first-build handoff section** (lines 122-152):
```markdown
The first `chrome` build is long-running for a clean Chromium checkout.

screen session: prometheus-chromium-build
Log file: .context/chromium-build-screen.log
Exit status file: .context/chromium-build-screen.status
```

Convert this to a completed-build evidence section. Keep the log/status paths, but state current evidence: `screen -ls` found no sockets, status file is `0`, and the log says the build finished successfully.

**Build args pattern to preserve** (lines 177-189):
```gn
is_debug = false
is_component_build = true
symbol_level = 0
```

Keep these args and rationale. Phase 11 is not changing Chromium build settings.

## Shared Patterns

### Single Canonical Preservation Dossier

**Source:** `11-CONTEXT.md` lines 20-22 and `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` lines 333-343
**Apply to:** dossier, README, STATE, Chromium handoff

All preservation facts should converge into `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`. Helper scripts can verify facts, but they must not become a second source of truth.

### License Boundary

**Source:** `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` lines 53-80; `11-CONTEXT.md` lines 29-32
**Apply to:** all migration rows and README legal language

Default to contract preservation and Chromium-native reimplementation. Do not write "port Falkon code" without an explicit `license_review_required` marker and future owner.

### Deferred Human Verification Carry-Forward

**Source:** `08-VERIFICATION.md` lines 192-255; `09-VERIFICATION.md` lines 168-208; `10-VERIFICATION.md` lines 145-195
**Apply to:** dossier visual-check ledger and future validation references

Convert all 26 items into `VIS-08-*`, `VIS-09-*`, and `VIS-10-*` rows. Do not mark visual quality complete from static verification alone.

### Stale State Reconciliation

**Source:** `11-RESEARCH.md` lines 360-369; `.planning/STATE.md` lines 1-8, 25-30, 144, 192; `.planning/chromium/CHROMIUM-CHECKOUT.md` lines 5 and 122-152
**Apply to:** README, STATE, Chromium handoff, optional verification script

Allowed reference-only Falkon paths should stay in the dossier. False claims that `falkon/` is active or that a Chromium build screen is running should be removed or marked superseded.

### Git Preservation Evidence

**Source:** `11-RESEARCH.md` lines 188-205
**Apply to:** dossier evidence block and optional verification script

Use Git-native checks: `git bundle verify`, `git ls-remote`, patch count, and a temporary clone under `.context/falkon-preservation/restore-check-*`. Do not use tar/zip archives as the primary preservation proof.

## No Analog Found

No file in the extracted Phase 11 scope lacks a usable analog. The only intentional gap is legal approval: no reviewer/approval artifact exists, so migration rows should use `license_review_required` instead of inventing approval.

## Metadata

**Analog search scope:** `.planning/`, `README.md`, `.context/falkon-preservation/`, root docs; `.context/chromium/` skipped because it is a large external checkout.
**Files scanned:** 3187 markdown/script files outside `.context/chromium`; 164 planning files.
**Project instructions:** no root `CLAUDE.md`; no project-local `.claude/skills/` or `.agents/skills/` `SKILL.md` files found.
**Dirty worktree note:** `.planning/config.json` had an unrelated pre-existing modification and was not touched.
**Pattern extraction date:** 2026-06-23
