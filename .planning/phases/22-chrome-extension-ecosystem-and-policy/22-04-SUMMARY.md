---
phase: 22-chrome-extension-ecosystem-and-policy
plan: 04
subsystem: browser-agent
tags: [chromium, extensions, mv3, mv2, compatibility, webui, gn]

requires:
  - phase: 22-01
    provides: Generation-bound extension inventory, regular/Private grant lattice, lifecycle authority, and bounded health types
  - phase: 22-02
    provides: Browser-owned extension surface resolution and policy-gated Agent dispatch
  - phase: 22-03
    provides: Local extension policy UI and the Parity Matrix "Extension compatibility" markup/renderer awaiting real backend data
provides:
  - Exactly five Prometheus-owned deterministic MV3 fixtures (password-manager-like, ad blocker, productivity content script, side panel/tooling, developer workflow) with category-specific isolation, proven native lifecycle, and zero retry/skip/fail
  - A closed, compiled five-row extension-compatibility catalog (category/fixture/version/SHA-256, manifest version, install source, Prometheus build, Chromium revision, regular/Private mode exercised, actions, Verified/Degraded/Unsupported result, bounded limitation, evidence artifact) projected into the existing Parity Matrix
  - An observation-only, non-acceptance Manifest V2 pinned-policy proof (native accepted/rejected result, one stable reason) kept structurally separate from the five-row MV3 catalog
  - Machine-readable 22-COMPATIBILITY.json/.md and 22-MV2-OBSERVATION.json evidence, regenerated and schema-validated from a fresh fixture run
  - Static claim-language, no-bypass, catalog-freshness, and UI-projection gates in verify-phase-22-extension-fixtures.sh
affects: [22-05-built-app-and-closeout, 23-cross-capability-security-and-parity]

tech-stack:
  added: []
  patterns:
    - Closed compiled evidence catalog with a WebUI-shaped row projector, separate from the machine-readable JSON evidence generator, cross-checked only on the narrow facts that must agree (fixture SHA-256, category keys) rather than byte-identical prose
    - Compile-command synthesis must select a template object that is genuinely wired into a `subninja` reachable from toolchain.ninja (pre-Phase-22 objects such as prometheus_runtime_profile_service.o), never another synthesized-only object
    - Native browser-test evidence written twice: as gtest RecordProperty (for a full test-launcher aggregation) and directly to a caller-supplied file path (the reliable path in this synthesized-binary harness)

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_compatibility_catalog.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_compatibility_catalog.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_compatibility_catalog_unittest.cc
    - .context/chromium/src/chrome/test/data/prometheus/extensions/mv2_observation/manifest.json
    - .context/chromium/src/chrome/test/data/prometheus/extensions/mv2_observation/background.js
    - .planning/phases/22-chrome-extension-ecosystem-and-policy/22-COMPATIBILITY.json
    - .planning/phases/22-chrome-extension-ecosystem-and-policy/22-COMPATIBILITY.md
    - .planning/phases/22-chrome-extension-ecosystem-and-policy/22-MV2-OBSERVATION.json
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_fixtures_browsertest.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-22-extension-fixtures.sh
    - .planning/chromium/verify-phase-22-webui.sh

key-decisions:
  - "Give the compatibility catalog its own source_set target (not folded into prometheus_extension_policy_service) so its object path is self-consistent under the project's manual compile-synthesis verification harness, and add it as a direct dep of the WebUI's side_panel_ui target."
  - "Bake all five catalog rows as compile-time constants (fixture SHA-256, build, revision, last_verified) representing a snapshot of proven evidence, and let the bash/node evidence generator independently recompute the same facts fresh from disk, cross-checked only where it matters (hash, category keys) rather than requiring byte-identical prose."
  - "Treat the MV2 observation as accept-or-reject agnostic: the browser test never asserts a specific outcome, only records whichever the pinned Chromium native policy produces."
  - "Record MV2 observation results directly to a caller-supplied file (in addition to gtest RecordProperty) because RecordProperty was not reliably surfacing through --test-launcher-summary-output in this project's synthesized-binary browser-test harness."

patterns-established:
  - "Extension compatibility catalog rows are a closed, bounded, compile-time snapshot; the JSON/Markdown evidence mirror is regenerated fresh from disk and validated for structural (not prose) agreement with the compiled catalog."
  - "New Prometheus C++ files must pick a genuinely Siso-known template object (one predating the file that first broke `gn gen`, e.g. prometheus_runtime_profile_service.o) for the project's manual compile-synthesis trick; a previously-synthesized object is never a valid template."

requirements-completed: [EXT-02, EXT-04, EXT-05, EXT-06]

duration: 3h 5m
completed: 2026-07-29
---

# Phase 22 Plan 04: Extension Fixtures and Compatibility Truth Summary

**Five deterministic MV3 fixtures with category-specific isolation, a compiled five-row Verified compatibility catalog wired into the real Parity Matrix, and a separate MV2 pinned-policy observation showing native unpacked load rejection (unpacked_load_failed)**

## Performance

- **Duration:** 3h 5m
- **Started:** 2026-07-29T13:28:02Z
- **Completed:** 2026-07-29T16:30:50Z
- **Tasks:** 3
- **Files modified:** 39 root and nested repository paths

## Accomplishments

- Proved exactly five Prometheus-owned MV3 fixtures (password-manager-like, ad blocker, productivity content script, side panel/tooling, developer workflow) through native Chromium lifecycle, each with its own isolation denial and zero retry/skip/failure.
- Added a closed, compiled `prometheus_extension_compatibility_catalog` with exactly five rows (category, fixture name/version/SHA-256, manifest version, install source, Prometheus build, Chromium revision, regular/Private mode exercised, actions exercised, `Verified`/`Degraded`/`Unsupported` result, bounded limitation, evidence artifact) and a WebUI-shaped row projector.
- Replaced the fixed `"unsupported"`/`"No verified fixture"` Parity Matrix placeholder in `prometheus_web_ui.cc` with the real catalog projection; added a browser test proving the real native data (not a JS-only fixture) reaches the rendered DOM.
- Added the observation-only `mv2_observation` MV2 fixture and `ManifestV2PinnedPolicyObservation`, which loads it through the ordinary `UnpackedInstaller` path with no MV2 allowance helper or verification bypass. On this pinned Chromium revision the native result is **rejected**, reason `unpacked_load_failed` (manifest parses, but `UnpackedInstaller`'s modern-manifest-version requirement rejects it before install) — observed and recorded, never asserted.
- Generated and schema-validated `22-COMPATIBILITY.json`/`.md` (five unique `Verified` MV3 rows, current build/revision, valid SHA-256 hashes) and `22-MV2-OBSERVATION.json` (manifest_version 2, kept structurally outside the five-row catalog) from a fresh fixture run.
- Added static claim-language, no-bypass, catalog-freshness (compiled hash vs. on-disk fixture), and UI-projection gates to `verify-phase-22-extension-fixtures.sh`.

## Task Commits

Each task was committed atomically in both repositories:

1. **Task 1 [22-04-01 / Wave 0 owner]: Create exactly five deterministic MV3 fixtures and retained RED category contracts**
   - Root: `c20e42c1c` — Chromium: `8ba88e08c1`
2. **Task 2 [22-04-01]: Make the five category, lifecycle, policy, and Private matrices GREEN**
   - Root: `8797e55b1` — Chromium: `cdaff22b49`
3. **Task 3 [22-04-02]: Generate exact compatibility evidence and observe Manifest/Web Store truth without overrides**
   - Root: `d46dd1bf9` — Chromium: `c3dc3f6104`

_Note: Tasks 1 and 2 were already complete and committed at the start of this execution session; this session verified their artifacts, then executed and committed Task 3._

## Files Created/Modified

- `prometheus_extension_compatibility_catalog.{h,cc}` — Closed five-row compiled evidence catalog, result enum, WebUI row projector (`ExtensionCompatibilityRowToValue`), and a schema validator (`IsClosedExtensionCompatibilityCatalog`).
- `prometheus_extension_compatibility_catalog_unittest.cc` — 12 tests: exact five unique ordered category keys/labels, MV3-only, closed result vocabulary (with case/unknown rejection), valid lowercase-hex SHA-256, non-empty bounded evidence fields with distinct evidence artifacts, only-ad_blocker-exercises-Private, no Web Store/MV2 overclaim text, closed-catalog validator, exact bounded WebUI-dict shape with no raw hash leakage, lowercase status, and a byte-budget regression guard against the WebUI renderer's silent 160-byte placeholder fallback.
- `prometheus_extension_fixtures_browsertest.cc` — Added `ManifestV2PinnedPolicyObservation`: loads `mv2_observation` via `extensions::UnpackedInstaller::Create`, records `accepted|rejected` + one stable reason both as gtest properties and via direct `base::WriteFile` (under `base::ScopedAllowBlockingForTesting`) to the path passed via `--prometheus-mv2-observation-output`.
- `mv2_observation/manifest.json`, `mv2_observation/background.js` — Minimal, inert, observation-only MV2 fixture; not one of the five acceptance categories.
- `prometheus_web_ui.cc` — `BuildExtensionPolicySnapshot()` now projects `GetExtensionCompatibilityCatalog()` through `ExtensionCompatibilityRowToValue()` instead of a hardcoded five-row `"unsupported"` placeholder.
- `prometheus_web_ui_browsertest.cc` — Added `ParityMatrixRendersRealFiveCategoryCompatibilityEvidence`, proving the real compiled catalog (not a JS-only test fixture) renders five `Verified` rows with real fixture/version/manifest/source text and no stale placeholder.
- `chrome/browser/prometheus/BUILD.gn` — New `prometheus_extension_compatibility_catalog` source_set; registered the unittest in `prometheus_unittests`; fixed three pre-existing dead/incorrect dependency labels found while investigating `gn gen` (see Deviations).
- `chrome/browser/ui/webui/prometheus/BUILD.gn` — Added a direct dep from `side_panel_ui` to the new catalog target.
- `verify-phase-22-extension-fixtures.sh` — Compiles/links the catalog and its unittest from a genuinely Siso-known template; runs the closed catalog unit suite and the MV2 observation test (exactly-one-test gated, generous timeout); on a full run, recomputes fixture hashes fresh from disk and checks them against the compiled catalog, generates/validates `22-COMPATIBILITY.json`/`.md` and `22-MV2-OBSERVATION.json`, and runs static claim-language/no-bypass/UI-projection gates.
- `verify-phase-22-webui.sh` — Compiles the new catalog object (same genuine template) so the WebUI focused link keeps working; widened its focused filter to include the new Parity Matrix regression test.
- `patches/0015-*.patch` — Ordered source-only export of the Task 3 nested commit.
- `22-COMPATIBILITY.json`/`.md`, `22-MV2-OBSERVATION.json` — Generated machine-readable and human-readable evidence (see Verification for exact content proof).

## Decisions Made

- Kept the compatibility catalog as its own GN target rather than folding it into `prometheus_extension_policy_service`, so its manually-synthesized object path (`prometheus_extension_compatibility_catalog/prometheus_extension_compatibility_catalog.o`) is self-consistent and does not require inventing a directory/stem mismatch in the verify scripts.
- Baked catalog rows as an evidence snapshot (fixed SHA-256/build/revision/last_verified) rather than trying to compute them "live" inside a shipped browser; the bash/node generator independently recomputes the same facts from disk each run and the verify script's freshness gate greps the compiled source for the current hash, so drift between fixtures and the catalog fails loudly instead of silently.
- Left `install_path` at `web_store_unverified` (unchanged); a live Web Store capability probe is explicitly Plan 22-05's responsibility, not this plan's.
- Treated the five catalog rows' `regular_mode_exercised`/`private_mode_exercised` truthfully per fixture: only `ad_blocker`'s browser test explicitly calls `GetEffectiveGrant(..., /*private_mode=*/true)`, so only that row claims Private-mode exercise; the shared policy/surface-resolver unit tests (Plans 22-01/22-02) separately cover the full Private-mode lattice for every category.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed three pre-existing dead/incorrect BUILD.gn dependency labels**

- **Found during:** Task 3, while investigating why the new catalog files could not be registered cleanly
- **Issue:** `chrome/browser/prometheus/BUILD.gn` referenced `//chrome/browser/ui/views/side_panel/extensions` (no such directory/target exists; the real target is `//chrome/browser/ui/views/side_panel`), `//chrome/browser/ui/tabs:tab_features` (no such target; the real one is `:impl`), and three non-existent standalone targets `:prometheus_page_action_dispatcher`/`:prometheus_page_element_reader`/`:prometheus_page_snapshot` (those files are actually part of the `:prometheus_page_adapter` source_set). These were introduced in Plan 22-02 and never caught because this project's established workflow builds new Prometheus objects via direct Siso compile-command synthesis rather than `gn gen`.
- **Fix:** Corrected the three dependency labels. Left a genuine, unrelated circular-dependency chain (`prometheus_extension_surface_resolver` → `//chrome/browser/ui` → ... → back to `prometheus_extension_surface_resolver`) undisturbed — untangling it is an architectural change out of this task's scope (Rule 4), so `gn gen` was not pursued to completion; this project's proven synthesis-based verification path does not require it.
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`
- **Verification:** Both verify scripts' focused/full runs pass with `.ninja_log`/`.ninja_deps` byte-identical before/after.
- **Committed in:** `c3dc3f6104` / `d46dd1bf9`

**2. [Rule 3 - Blocking] Compile-command synthesis template must be a genuinely Siso-known object**

- **Found during:** Task 3, first attempt to compile the new catalog object
- **Issue:** Using `prometheus_extension_policy_service.o` (itself only ever produced by prior synthesis, never registered via a real `gn gen`) as the template made `siso query commands` return "unknown target" for it, and thus for anything synthesized from it.
- **Fix:** Switched the template to `prometheus_runtime_profile_service.o`/`prometheus_agent_route_unittest.o` (pre-Phase-22 objects genuinely wired into `toolchain.ninja`'s `subninja` list), matching the pattern every other Phase 22 synthesized object already uses.
- **Files modified:** `.planning/chromium/verify-phase-22-extension-fixtures.sh`, `.planning/chromium/verify-phase-22-webui.sh`
- **Verification:** Both scripts' focused/full runs compile and link successfully.
- **Committed in:** `d46dd1bf9`

**3. [Rule 1 - Bug] RecordProperty did not surface through --test-launcher-summary-output**

- **Found during:** Task 3, generating `22-MV2-OBSERVATION.json` from the MV2 test's recorded properties
- **Issue:** The per-test `properties` object in `--test-launcher-summary-output`'s JSON was consistently empty in this synthesized-binary browser-test harness, even though the test passed and called `RecordProperty` normally.
- **Fix:** Added a second, direct recording path: the test writes `{mv2_observation_result, mv2_observation_reason, mv2_observation_manifest_version}` via `base::WriteFile` (under `base::ScopedAllowBlockingForTesting`) to the path passed via a new `--prometheus-mv2-observation-output` switch; `verify-phase-22-extension-fixtures.sh` parses that file as the primary evidence source, while `--test-launcher-summary-output` remains a required freshness gate (proves the launcher produced fresh per-test output for this run) without being the parse source.
- **Files modified:** `prometheus_extension_fixtures_browsertest.cc`, `.planning/chromium/verify-phase-22-extension-fixtures.sh`
- **Verification:** `22-MV2-OBSERVATION.json` generated correctly with `result: "rejected"`, `reason: "unpacked_load_failed"`.
- **Committed in:** `c3dc3f6104` / `d46dd1bf9`

**4. [Rule 1 - Bug] WebUI renderer silently truncated the `limitation` field to its placeholder**

- **Found during:** Task 3, the new `ParityMatrixRendersRealFiveCategoryCompatibilityEvidence` browser test failed with the retired placeholder text still appearing
- **Issue:** `prometheus_webui.js`'s `controlExtensionText(row?.limitation, ..., 160)` silently substitutes a generic placeholder for any `limitation` value over 160 bytes; the original catalog limitation text plus its shared suffix totaled ~300 bytes per row, so every row silently fell back to `"Representative compatibility evidence has not run in this build."` with no runtime error.
- **Fix:** Shortened every row's `limitation` text and the shared suffix so every combined value is well under the 160-byte budget (129–139 bytes observed); added a unit test (`ProjectedLimitationStaysUnderTheWebUiRendererByteBudget`) asserting the exact projected value and its byte length, so a future regression fails a fast C++ unit test instead of only a slow browser-test DOM assertion.
- **Files modified:** `prometheus_extension_compatibility_catalog.cc`, `prometheus_extension_compatibility_catalog_unittest.cc`, `.planning/chromium/verify-phase-22-extension-fixtures.sh` (JSON generator's mirrored limitation strings)
- **Verification:** `ParityMatrixRendersRealFiveCategoryCompatibilityEvidence` passes; catalog unit suite passes 12/12.
- **Committed in:** `c3dc3f6104` / `d46dd1bf9`

**5. [Rule 1 - Bug] base::WriteFile on the UI thread requires ScopedAllowBlockingForTesting**

- **Found during:** Task 3, first run of the MV2 observation test after adding the direct file-write
- **Issue:** The test crashed with `DCHECK failed: !tls_blocking_disallowed` — `base::WriteFile` performs blocking I/O, disallowed by default on the thread the browser-test body runs on.
- **Fix:** Wrapped the write in `base::ScopedAllowBlockingForTesting`.
- **Files modified:** `prometheus_extension_fixtures_browsertest.cc`
- **Verification:** Test passes without crashing.
- **Committed in:** `c3dc3f6104`

**6. [Rule 3 - Blocking] Split hash string literals broke the freshness grep gate**

- **Found during:** Task 3, first full (non-focused) verify run
- **Issue:** Each catalog row's `fixture_sha256` was written as two adjacent C++ string-literal lines for formatting; as plain text this splits the 64-character hash across a line boundary, so `rg -qF "<hash>"` could never find it as a contiguous substring even though the compiled value was correct.
- **Fix:** Reformatted each hash as a single unbroken string-literal line.
- **Files modified:** `prometheus_extension_compatibility_catalog.cc`
- **Verification:** `verify_catalog_matches_fixtures_on_disk` passes for all five rows.
- **Committed in:** `c3dc3f6104`

**7. [Rule 3 - Blocking] Range-based-for over base::DictValue must not bind by reference**

- **Found during:** Task 3, first compile of the catalog unit test
- **Issue:** `for (const auto& [key, entry] : value)` triggered `-Wrange-loop-bind-reference` (treated as error): the dict's `const_dict_iterator::reference` is already `std::pair<const std::string&, const Value&>`, so binding it by reference-to-a-prvalue is flagged by Chromium's clang plugin.
- **Fix:** Changed to `for (const auto [key, entry] : value)` (binds the already-reference-shaped value type directly), matching Chromium's own style for this iterator.
- **Files modified:** `prometheus_extension_compatibility_catalog_unittest.cc`
- **Verification:** Compiles cleanly.
- **Committed in:** `c3dc3f6104`

---

**Total deviations:** 7 auto-fixed (2 bugs blocking compilation/linking, 1 pre-existing BUILD.gn bug, 1 pre-existing test-infrastructure limitation worked around, 2 correctness bugs caught by fresh verification, 1 blocking crash fix).
**Impact on plan:** All fixes were required to make the planned catalog, MV2 observation, and evidence-generation work actually compile, link, run, and render correctly. No scope creep beyond what Task 3 requires; the one architectural issue found (a genuine circular GN dependency) was explicitly left untouched as out of scope.

## Issues Encountered

- `gn gen` cannot currently complete for this checkout (a real circular dependency: `prometheus_extension_surface_resolver` → `//chrome/browser/ui` → ... → back to `prometheus_extension_surface_resolver`, introduced in Plan 22-02). This project's established workflow never relies on `gn gen` succeeding — every Prometheus object is compiled via direct Siso compile-command synthesis from a genuinely-registered template — so this did not block Task 3, but it remains latent for whichever future plan first needs a real `gn gen`/`autoninja` pass (likely Plan 22-05's built-app work). Flagging here rather than silently fixing, since resolving it requires a structural dependency change (Rule 4).
- Two MV2-observation test runs briefly hit the default 45s `--test-launcher-timeout` under heavy local system load from repeated consecutive browser-test invocations during this session's iteration; not a logic bug (the identical test completed in ~12s once given more time). Mitigated by passing an explicit `--test-launcher-timeout=90000` for the MV2 and catalog test invocations.

## User Setup Required

None — no external service configuration required.

## Verification

- `bash .planning/chromium/verify-phase-22-extension-fixtures.sh --focused --expect-failure` re-confirms the five category tests are GREEN (Task 2 already flipped them); this is the expected post-Task-2 state, not a regression.
- `bash .planning/chromium/verify-phase-22-extension-fixtures.sh --focused` passes: five category tests GREEN with zero retry/skip/fail, closed compatibility-catalog unit suite 12/12, MV2 observation test executed with fresh summary output.
- `bash .planning/chromium/verify-phase-22-extension-fixtures.sh` (full) passes: all of the above, plus catalog-vs-fixture freshness, `22-COMPATIBILITY.json` schema validation (five unique MV3 rows, closed results, current build/revision), Markdown-matches-JSON, `22-MV2-OBSERVATION.json` generation/validation, Control Panel WebUI projection check, and claim-language/no-bypass static gates — all passed, `.ninja_log`/`.ninja_deps` byte-identical before/after (`eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce` / `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`).
- `bash .planning/chromium/verify-phase-22-webui.sh --focused` passes 4/4 (3 existing extension-policy/confirmation tests plus the new `ParityMatrixRendersRealFiveCategoryCompatibilityEvidence`), with fresh GRIT/framework resources and unchanged Ninja metadata.
- `22-COMPATIBILITY.json` contains exactly five rows, each with `"manifest_version": 3`, a valid 64-character lowercase-hex `fixture_sha256`, `"result": "Verified"`, and the current nested revision `cdaff22b49f53572263eae29c61688b63ec3791e` / build `151.0.7898.0`.
- `22-MV2-OBSERVATION.json` contains `"manifest_version": 2`, `"result": "rejected"`, `"reason": "unpacked_load_failed"` — the pinned build's actual native behavior for an unpacked, non-component, developer-mode MV2 extension, observed without any MV2 allowance helper or install-verification bypass.
- Root and nested working trees are clean after both commits (verified via `git status --short`).

## Next Phase Readiness

- Plan 22-05 (built application and closeout) can proceed: the five-category fixture matrix, compiled compatibility catalog, and MV2 observation are all in place and independently verified. Plan 22-05 owns the live Web Store capability probe and the built-app lifecycle/Private-mode smoke.
- The latent `gn gen` circular-dependency issue (`prometheus_extension_surface_resolver` → `//chrome/browser/ui` → ...) should be resolved before any future plan attempts a real `gn gen`/`autoninja` pass; it is not blocking Plan 22-05's established synthesis-based verification approach.
- No Plan 22-04 implementation or verification blockers remain.

## Self-Check: PASSED

- All created files exist on disk (catalog `.h`/`.cc`/`_unittest.cc`, `mv2_observation` fixture, `22-COMPATIBILITY.json`/`.md`, `22-MV2-OBSERVATION.json`, patch `0015`).
- All six task commits resolve in their respective repositories (root: `c20e42c1c`, `8797e55b1`, `d46dd1bf9`; nested: `8ba88e08c1`, `cdaff22b49`, `c3dc3f6104`).
- Both root and nested working trees were clean before this summary was written.

---
*Phase: 22-chrome-extension-ecosystem-and-policy*
*Completed: 2026-07-29*
