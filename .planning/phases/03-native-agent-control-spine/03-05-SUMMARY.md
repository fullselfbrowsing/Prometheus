# Plan 03-05 Summary: Internal Surface, Errors, and Smoke

**Status:** Complete
**Date:** 2026-06-16

## Changes

- Added `open_internal_surface` for the native Preferences dialog.
- Added typed `unsupported_tool` and `unsupported_surface` errors.
- Added `tools/fsb-baseline/smoke-agent-control.sh` to exercise the native spine end to end.

## Verification

- Agent smoke opened Preferences through the native router.
- Agent smoke received `unsupported_tool` for an invalid command.
- Agent smoke confirmed audit JSONL exists and contains final success/error outcomes.
- Browser smoke still exits 0 after the agent spine changes.
