# Decision Record: Freeze v2.1-B and Hand Off Track D Operational Smoke

Date: 2026-08-09

Status: Accepted; draft-PR publication pending

## Decision

Freeze the current v2.1-B files and audit conclusions as research-grade envelope
exploration. Do not continue expanding them to eliminate every open P0/P1/P2, and
do not make that work a prerequisite for daily Track D use.

Track D becomes an operational smoke lane. Its next objective is one small,
low-risk, reversible, real repository change written by Grok and independently
verified by Codex. Operational results must be labelled `Track-D operational
smoke`; they are not RepoLens research observations and must not use LiveD2
instrument labels.

Publish this handoff on an isolated documentation branch so another agent can
resume without relying on private Notion access or local session history.

## Publication redaction decision

The initial handoff design proposed copying five frozen v2.1-B artifacts
byte-for-byte. Read-only inventory showed that the originals contain personal
absolute paths, private Notion identifiers, one-use temporary paths, and local
host fingerprints. Because the destination repository is remote, publication
was deliberately narrowed to sanitized historical derivatives plus the exact
original source hashes. This is a privacy-preserving scope reduction, not a
claim of byte-identical preservation. The untracked originals remain untouched
in the historical local worktree.

## Operational envelope

- Worker tools: exactly `read_file` and `search_replace`.
- Disabled: shell, web, subagents, memory, plan, skills, workflow, goal/todo, and
  other MCP/meta-tools.
- Bind repository, CWD, model, sole target file, maximum turns, wall time, and
  output shape before a live call.
- Grok writes only a candidate diff. Codex verifies the real file, `git diff`, and
  local project checks.
- Do not build a generic service or use ACP.
- Do not stage, commit, push, open a product PR, merge, deploy, or publish from the
  operational-smoke workflow.

## Attempt 01 consequence

Attempt 01 used a process-wide `ulimit -f 2048` to bound output. Zsh reported
status 153, raw and stderr capture files remained empty, the target stayed
unchanged, and no worker response or candidate diff existed. Keeper incident
review diagnosed the limit as also covering Grok's existing unified log, already
larger than one MiB, with a startup append raising `SIGXFSZ`.

This is classified as a Keeper launch failure, not evidence about Grok's ability
to perform the task. The causal explanation is a Keeper diagnosis based on local
incident observations; the private launch transcript and global log are not
published in this handoff. The attempt consumed its one-use authorization and
was not retried.

## Recommended improvement for a future proposal

Use the simple operational design, not another proof stack:

- remove the process-wide file-size limit;
- capture the CLI JSON response directly;
- keep final summary length at most 600 characters;
- cap Codex-side captured display at 2,000 tokens;
- use `grok-4.5`, low effort, at most three turns, and a 180-second wall timeout;
- retain exactly `read_file` and `search_replace` with one writable target;
- after exit, reject every repository change outside the target and run the local
  verifier.

This recommendation is offline design guidance only. It is not a live-call gate
or authorization. Before another xAI call, the next agent must present one concise
readiness page and obtain fresh owner approval.

## Alternatives considered

- Continue v2.1-B until every audit item closes: rejected as mission-budget drift.
- Add output-specific wrapper and pipe caps: deferred; too much machinery for the
  one-edit operational lane.
- Isolate a full alternate Grok home: rejected for now because it adds auth and
  configuration drift risk.
- Stop Track D entirely: rejected because a bounded real worker smoke still has
  direct daily value.

## Consequences

- v2.1-B remains readable history, with unresolved audit findings preserved.
- The next agent may perform offline preparation without reopening the envelope
  proof project.
- No future live call inherits attempt 01 authorization.
- Success requires an actual candidate diff plus Codex-owned verification; worker
  prose alone never counts.

## Next review

Immediately before the next proposed Grok/xAI operational-smoke call.
