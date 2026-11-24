# Phase 6: Supervision, Packaging, and Release Hardening - Context

**Gathered:** 2026-06-16
**Status:** Ready for execution

<domain>
## Phase Boundary

Phase 6 hardens Prometheus into a supervised and packageable local build. It should add DOM-native supervision primitives, stale-session-safe pairing, a repeatable macOS artifact, legal/source-availability bundle checks, and a release validation script that runs the build and core smokes.

</domain>

<decisions>
## Implementation Decisions

- Add supervision as native router tools first, using DOM-native snapshots and hash-based diffs rather than pixel/video streaming.
- Require session IDs for supervision reads/diffs and reject unknown, expired, or target-mismatched sessions.
- Package the existing built `.app` into a local validation artifact with a `LEGAL/` bundle and source-availability notice.
- Treat release validation as a scriptable gate that runs syntax checks, build, browser smoke, native agent/runtime/supervision smoke, MCP smoke, packaging, and legal bundle checks.

</decisions>

<verification>
## Verification Strategy

- Build Prometheus after adding supervision session state.
- Expand native agent smoke to verify pairing, snapshot, diff, stale-session rejection, and session end.
- Run release validation end to end.
- Inspect the packaged tarball for the app and legal files.

</verification>
