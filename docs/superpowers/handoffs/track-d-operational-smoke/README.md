# Track D Operational Smoke Handoff

Status: `PREPARED / DRAFT PR PENDING / NO LIVE AUTHORITY`

This directory is the self-contained handoff for the daily Track D worker lane.
It is deliberately separate from RepoLens-NG research observations and the
LiveD2 research instrument.

## Start here

1. Read [DECISION.md](DECISION.md) for the scope and frozen decisions.
2. Read [operational/attempt-01/RESULT.md](operational/attempt-01/RESULT.md) for
   the failed first smoke and the Keeper diagnosis.
3. Read [NEXT_AGENT.md](NEXT_AGENT.md) before preparing another attempt.
4. Verify the handoff from the repository root:

   ```bash
   shasum -a 256 -c docs/superpowers/handoffs/track-d-operational-smoke/manifest.sha256
   ```

## Current state

- The mobile-navigation objective was completed by PR #85 and is retired.
- Track D is now an operational smoke lane whose goal is one real Grok-written
  candidate diff independently verified by Codex.
- Attempt 01 targeted one metadata line in `gm-crypto-rs-demo`. It failed during
  Grok startup, before any response or candidate diff. The Keeper diagnosis is
  that a process-wide file-size limit also covered Grok's existing unified log.
- The target repository was restored clean and unchanged. The verifier correctly
  rejected the no-diff result. No retry occurred.
- The prior live authorization was consumed by attempt 01. Nothing in this
  directory authorizes another Grok/xAI call.

## What is current

- [DECISION.md](DECISION.md): authoritative scope and consequence record.
- [NEXT_AGENT.md](NEXT_AGENT.md): bounded takeover sequence.
- [operational/packet.template.md](operational/packet.template.md): portable
  packet template for the same small candidate task.
- [operational/command.template.md](operational/command.template.md): non-live
  exact CLI shape and flag-to-constraint mapping.
- [operational/verify.sh](operational/verify.sh): Codex-owned independent
  verifier; it is never a worker tool.
- [operational/plugin-config.toml](operational/plugin-config.toml): required
  run-local plugin suppression configuration, installed and removed by Keeper.

## What is historical

The [archive/v2.1b](archive/v2.1b/) directory preserves a sanitized snapshot of
the frozen v2.1-B research-grade envelope exploration. It is not an executable
gate, a prerequisite for daily work, or a reason to add more launcher, invoker,
helper, or generic-service proof layers. Original local source hashes are recorded
there; archive bytes intentionally differ because private paths and Notion page
identifiers were removed.

## Non-goals

- No RepoLens research-observation claim.
- No LiveD2 instrument label or data mixing.
- No generic Agent Service.
- No product change by Codex; Grok may produce only a candidate diff after a new
  owner authorization.
- No stage, commit, push, PR, merge, deploy, publish, or ACP action in the smoke
  workflow itself. This handoff branch and draft PR are a separately authorized
  documentation publication.
- No worker self-report as evidence.

The repository files, `git diff`, and local verifier output are the evidence.
The verifier proves tracked and untracked Git scope, not ignored-path
immutability; that residual must be stated in the one-page readiness.
