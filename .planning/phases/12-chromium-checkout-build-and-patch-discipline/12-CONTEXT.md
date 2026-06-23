# Phase 12: Chromium Checkout, Build, and Patch Discipline - Context

**Gathered:** 2026-06-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 establishes the clean upstream Chromium baseline before Prometheus-specific Chromium patches begin. It must verify the existing checkout/build state, prove that the unmodified Chromium app launches, document the macOS developer workflow, and enforce isolation so Chromium source, `.gclient`, `out/`, depot_tools, caches, logs, and generated artifacts do not pollute the root planning repository.

This phase does not rebrand Chromium, port Prometheus UI, modify browser behavior, or begin feature work. Those belong to later Chromium migration phases.

</domain>

<decisions>
## Implementation Decisions

### Unmodified Launch Proof
- **D-01:** A passing launch check requires the built Chromium app to start, open a local or `data:` smoke page, exit cleanly, and leave recorded evidence.
- **D-02:** The normal launch path should be attempted by default. Document `--disable-features=DialMediaRouteProvider` as a macOS development workaround for repeated local network permission prompt noise, but do not make it the default baseline proof unless needed.
- **D-03:** Phase 12 evidence should record the launch command, Chromium revision, GN args, status, and log/status file paths. Full stdout/stderr transcripts are not required unless needed for failure diagnosis.
- **D-04:** If the clean Chromium build succeeds but unmodified launch verification fails, Prometheus-specific Chromium patches are blocked until the launch blocker is fixed or explicitly documented as a launch blocker.

### Build And Run Scripts
- **D-05:** Add small planning-owned scripts under `.planning/chromium/` for environment checks, GN/build reproduction, and unmodified launch smoke. Do not add root-level product scripts in this phase.
- **D-06:** Scripts should verify the existing checkout at `.context/chromium/src` and provide remediation when it is missing. They should not run `fetch chromium` automatically during normal validation because checkout is large, slow, and risky in agent runs.
- **D-07:** Environment checks should fail fast with exact remediation for Xcode, Metal toolchain, depot_tools, GN args, Chromium source path, build directory, and binary path before running long commands.
- **D-08:** Scripts must be Conductor-friendly: use explicit paths and environment variables, avoid fixed ports and global state, avoid relying on interactive shell profile setup, and write predictable logs/status files.

### Patch Discipline
- **D-09:** Future Chromium source modifications happen inside `.context/chromium/src` and are managed by the Chromium checkout's git state. The root Prometheus planning repo stores docs, scripts, evidence, and exported patch guidance, not copied Chromium source files.
- **D-10:** Phase 12 should add or verify isolation gates for `.context/`, `.gclient`, Chromium `out/`, depot_tools, logs, caches, and build artifacts so the root repo cannot accidentally commit massive generated directories.
- **D-11:** Record the upstream Chromium baseline revision and define future patch branch/export expectations before branding work starts. Do not commit Prometheus changes directly on Chromium `main` without branch/export discipline.
- **D-12:** If root git becomes dirty because of Chromium checkout/build artifacts, planning or execution must stop until the artifact is cleaned, ignored, or isolated.

### the agent's Discretion
- Exact script filenames, shell helper structure, smoke-page content, and log/status file names are at the planner's discretion as long as the decisions above are satisfied.
- The planner may decide whether the isolation gate is implemented as shell, Node, or documented commands, provided it checks real root git tracking/ignore behavior.
- The planner may preserve the existing GN args unless a baseline validation issue requires changing them with documented rationale.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Phase 12 goal, requirements, success criteria, and planned work.
- `.planning/REQUIREMENTS.md` - CHROM-01 through CHROM-08 define the baseline, build, launch, reproducibility, and artifact-isolation requirements.
- `.planning/PROJECT.md` - v2.0 Chromium migration goals, locked product constraints, and the rule that Falkon is preserved reference only.
- `.planning/STATE.md` - accumulated current evidence: Chromium checkout revision, Xcode/Metal fixes, successful GN generation/build, and pending launch verification.

### Chromium Baseline Evidence
- `.planning/chromium/CHROMIUM-CHECKOUT.md` - current handoff for depot_tools, `.context/chromium/src`, recorded Chromium revision, GN args, successful first build, and launch command.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - migration contract and license boundary that Phase 12 must respect before later Chromium work.
- `.planning/preservation/verify-preservation.sh` - existing fail-fast verification style and root artifact-isolation checks that Phase 12 scripts can mirror.

### Project-Facing Documentation
- `README.md` - current v2.0 status, Quick Start, repository layout, and statement that launch verification remains Phase 12 scope.
- `.planning/phases/11-preservation-contract-and-falkon-freeze/11-CONTEXT.md` - prior phase decisions about preservation artifacts, Chromium owner phases, source freeze, and stale-state reconciliation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/chromium/CHROMIUM-CHECKOUT.md`: Already records depot_tools path, Chromium source path, exact revision `0e8499df5172f55d0d29e2b92ef7e6a704529578`, GN args, successful build evidence, and the unmodified launch command.
- `.planning/preservation/verify-preservation.sh`: Provides a local pattern for fail-fast shell checks with clear remediation and artifact-isolation assertions.
- `.context/chromium/src/out/Default/Chromium.app`: The built unmodified Chromium app exists locally and is the launch target for Phase 12 validation.
- Root gitdir exclude: `.context/` is ignored through the shared repo gitdir at `/Users/lakshman/conductor/repos/prometheus/.git/info/exclude`; Phase 12 should verify this behavior and decide whether to make fresh-clone isolation more reproducible.

### Established Patterns
- Planning-owned operational scripts belong under `.planning/` when they verify workflow/state rather than product runtime behavior.
- Large external checkouts and generated artifacts live under `.context/` and should stay out of root git commits.
- Baseline gates should fail with concrete evidence instead of silently passing when local dependencies are missing.

### Integration Points
- `.planning/chromium/` is the natural home for Phase 12 scripts and updated baseline notes.
- `.context/depot_tools` and `.context/chromium/src` are the local tool/source paths used by existing handoff commands.
- Root git status and `git check-ignore` are required integration points for artifact-isolation validation.
- Later phases should consume the recorded baseline revision and patch discipline before introducing Prometheus-specific Chromium modifications.

</code_context>

<specifics>
## Specific Ideas

- Use a smoke launch that opens local or `data:` content so baseline verification does not depend on network availability.
- Preserve the existing baseline build args unless there is a documented reason to change them: `is_debug=false is_component_build=true symbol_level=0`.
- Keep the first proof practical: enough evidence for downstream agents to trust the baseline without storing large logs in the root repo.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 12 scope.

</deferred>

---

*Phase: 12-chromium-checkout-build-and-patch-discipline*
*Context gathered: 2026-06-23*
