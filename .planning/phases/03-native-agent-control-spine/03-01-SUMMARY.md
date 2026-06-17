# Plan 03-01 Summary: Router, Server, Envelopes, and Audit

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Added `AgentCommandRouter` under `falkon/src/lib/agent/`.
- Added a loopback JSON command server enabled by `PROMETHEUS_AGENT_PORT`.
- Added `/health` and `POST /agent/command`.
- Added normalized envelopes with `ok`, `id`, `tool`, `result` or typed `error`, and `audit.sequence`.
- Added JSONL audit logging at the active Prometheus config path.

## Verification

- `cmake --build build/fsb-baseline` exited 0.
- Agent smoke confirmed `/health` returns JSON and reports the audit path.
