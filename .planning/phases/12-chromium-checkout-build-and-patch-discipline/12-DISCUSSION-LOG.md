# Phase 12: Chromium Checkout, Build, and Patch Discipline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-23
**Phase:** 12-Chromium Checkout, Build, and Patch Discipline
**Areas discussed:** Unmodified launch proof, Build/run scripts, Patch discipline

---

## Unmodified Launch Proof

### Passing launch check

| Option | Description | Selected |
|--------|-------------|----------|
| Process + smoke page | App starts, opens a local/data page, exits cleanly, and logs evidence. | Yes |
| Visual/manual only | Developer launches Chromium and records that the window appeared. | No |
| Process only | Binary starts without immediate crash; no page smoke required. | No |

**User's choice:** Process + smoke page.
**Notes:** User selected all recommended options for this area.

### Launch workaround flag

| Option | Description | Selected |
|--------|-------------|----------|
| Use when needed | Default normal launch; document `--disable-features=DialMediaRouteProvider` for macOS network prompt noise. | Yes |
| Always use it | Consistent local command, less prompt noise. | No |
| Never use it | Baseline should be completely vanilla. | No |

**User's choice:** Use when needed.
**Notes:** The workaround is documentation/remediation, not the default proof unless needed.

### Evidence to record

| Option | Description | Selected |
|--------|-------------|----------|
| Command, revision, args, status, log path | Enough for downstream agents to trust the baseline. | Yes |
| Minimal status note | Just record pass/fail in the handoff doc. | No |
| Full transcript | Save all stdout/stderr from launch attempts. | No |

**User's choice:** Command, revision, args, status, log path.
**Notes:** Full transcripts are only needed for failure diagnosis.

### Launch failure policy

| Option | Description | Selected |
|--------|-------------|----------|
| Block Prometheus patches | Fix or document the launch blocker before branding/feature work. | Yes |
| Allow docs/scripts only | No Chromium source patches yet, but cleanup docs can proceed. | No |
| Proceed with later phases | Record launch as known issue. | No |

**User's choice:** Block Prometheus patches.
**Notes:** Clean baseline launch is a gate before Prometheus-specific Chromium modifications.

---

## Build/run Scripts

### Script surface

| Option | Description | Selected |
|--------|-------------|----------|
| Small scripts under `.planning/chromium/` | Reproducible planning-owned wrappers for env check, GN gen/build, and launch smoke. | Yes |
| Root-level scripts | Easier to find, but noisier in the product repo. | No |
| Documentation only | Commands in markdown, no executable wrappers. | No |

**User's choice:** Small scripts under `.planning/chromium/`.
**Notes:** User selected all recommended options for this area.

### Checkout assumption

| Option | Description | Selected |
|--------|-------------|----------|
| Verify, don't fetch by default | Scripts validate the existing checkout and tell the user how to fetch if missing. | Yes |
| Fetch automatically | More turnkey, but expensive and risky in agent runs. | No |
| Separate fetch script | Available, but never part of normal validation. | No |

**User's choice:** Verify, don't fetch by default.
**Notes:** Normal validation must not unexpectedly run a huge Chromium checkout.

### Environment strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Fail fast with exact remediation | Verify Xcode, Metal toolchain, depot_tools, GN args, and binary paths before long commands. | Yes |
| Best effort | Try the command and let Chromium tooling fail. | No |
| Advisory only | Print warnings but continue. | No |

**User's choice:** Fail fast with exact remediation.
**Notes:** Missing dependencies should be explicit blockers, not ambiguous Chromium failures.

### Conductor friendliness

| Option | Description | Selected |
|--------|-------------|----------|
| No fixed ports/global state | Scripts use explicit paths/env vars, write logs/status files, and avoid assuming interactive shell setup. | Yes |
| Match local terminal habits | Rely on the developer's shell/profile state. | No |
| Minimal wrapper | Only set `PATH` and `DEVELOPER_DIR`. | No |

**User's choice:** No fixed ports/global state.
**Notes:** Scripts should work predictably from Conductor workspaces.

---

## Patch Discipline

### Modification location

| Option | Description | Selected |
|--------|-------------|----------|
| Inside `.context/chromium/src`, tracked by Chromium git | Root repo stores docs/scripts/evidence; Chromium changes are patch-series or branch-managed in the Chromium checkout. | Yes |
| Copy changed Chromium files into root | Easier to review in this repo, but risks massive/fragile source ownership. | No |
| Root repo owns a mirror subtree | Heavier and more complex. | No |

**User's choice:** Inside `.context/chromium/src`, tracked by Chromium git.
**Notes:** User selected all recommended options for this area.

### Artifact protection

| Option | Description | Selected |
|--------|-------------|----------|
| Verify ignore/isolation gates | Check `.context/`, `.gclient`, `out/`, depot_tools, logs, and build artifacts are ignored/untracked. | Yes |
| Rely on current local exclude only | Enough for this workspace, less reproducible. | No |
| Commit a broad root `.gitignore` change only | Useful, but does not prove actual isolation. | No |

**User's choice:** Verify ignore/isolation gates.
**Notes:** The current workspace ignores `.context/` via gitdir exclude; Phase 12 should verify real behavior.

### Patch recording

| Option | Description | Selected |
|--------|-------------|----------|
| Baseline revision + patch branch/export discipline | Record upstream revision, local branch naming, and patch export expectations. | Yes |
| Commit directly on Chromium `main` | Simple but poor rebase hygiene. | No |
| Defer patch recording until branding work starts | Leaves downstream phases without guardrails. | No |

**User's choice:** Baseline revision + patch branch/export discipline.
**Notes:** Patch discipline should be documented before Phase 13 branding work starts.

### Root git contamination

| Option | Description | Selected |
|--------|-------------|----------|
| Block planning/execution until cleaned or ignored | Prevents accidental massive commits. | Yes |
| Warn only | Keep moving unless commit fails. | No |
| Let commit tooling catch it later | Delays detection. | No |

**User's choice:** Block planning/execution until cleaned or ignored.
**Notes:** Root repo cleanliness is a hard gate for this migration baseline.

---

## the agent's Discretion

- Exact script filenames, smoke page content, helper structure, and log/status file names.
- Choice of shell or Node for isolation checks.
- Exact wording of remediation output as long as failures are concrete and actionable.

## Deferred Ideas

None.
