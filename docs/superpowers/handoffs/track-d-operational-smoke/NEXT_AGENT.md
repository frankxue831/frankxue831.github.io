# Next Agent Guide

This guide is intentionally short. Do not expand the handoff into another
research-grade envelope project.

## 1. Verify the handoff

From the repository root:

```bash
git status -sb
shasum -a 256 -c docs/superpowers/handoffs/track-d-operational-smoke/manifest.sha256
```

Read `README.md`, `DECISION.md`, and `operational/attempt-01/RESULT.md`. Treat the
sanitized v2.1-B archive as history only. Do not execute its RED harness.

## 2. Recheck the candidate repository offline

Candidate repository:

```text
https://github.com/frankxue831/gm-crypto-rs-demo.git
```

Attempt 01 bound commit:

```text
53d7a4d27ebb396b541f9c12a439667a7db45569
```

Do not assume that commit is still current. Fetch read-only, verify the selected
branch, exact HTTPS origin spelling, and a clean worktree, and confirm the
metadata mismatch still exists. If the task is already resolved, the bound HEAD
has moved, or the repository is not clean, stop this handoff. A different task
requires a new packet and verifier; do not adapt this fixed verifier in place.

## 3. Prepare one bounded attempt

- Allocate a fresh attempt ID and evidence directory; never reuse attempt 01.
- Fill `operational/packet.template.md` with current repository identity and
  current before/after target hashes.
- Render the filled packet and command into fresh attempt evidence files. Require
  `rg -n '\{\{[^}]+\}\}' <rendered-packet> <rendered-command>` to find no
  unresolved placeholders; do not scan the source templates themselves.
- Use `operational/command.template.md` as the reviewed CLI shape and preserve
  its flag-to-constraint mapping.
- Keep the model at `grok-4.5`, effort low, maximum turns three, wall time 180
  seconds, and sole worker tools `read_file,search_replace`.
- Allow edits only to the exact target file. Disable shell, web, subagents,
  memory, plan, skills, workflows, goal/todo, and other meta-tools.
- Do not use a process-wide `RLIMIT_FSIZE` or `ulimit -f`; it also limits Grok's
  own log files.
- Capture direct structured output, with a summary no longer than 600 characters.
- Before any Grok process, require `{{TARGET_REPO}}/.grok/config.toml` to be
  absent. Keeper creates the `.grok` directory if needed, copies the exact bytes
  of `operational/plugin-config.toml` to that path, and requires SHA-256
  `679a6066749bce97740a109f243279d7dc873b2fbae248c2014bcf1954e2c03f`.
- With that file installed, run the offline `inspect --json` preflight defined in
  `operational/command.template.md`. Stop unless it shows `superpowers` disabled,
  no active hook, no active MCP, and no unexpected plugin skill/tool surface.
- Run `cargo fetch --locked` as an explicit offline-preparation step if the local
  Cargo cache is incomplete. The post-diff verifier itself uses `--offline`.
- Do not add a launcher framework, generic service, or new proof hierarchy.

## 4. Stop once before live traffic

Present the Product Owner with no more than one page containing:

- repository and exact task;
- exact tool surface;
- model and budgets;
- verifier;
- residual risks;
- exact proposed command.

Obtain fresh, explicit authorization before the first actual Grok/xAI call. This
handoff, branch, draft PR, and prior approval do not authorize it.

Required Keeper-side prerequisites are `/bin/zsh`, Git, `rg`, `jq`, `shasum`,
Cargo/Rust, and an HTTPS clone whose origin is exactly the URL above.

## 5. Verify independently after the call

Worker self-report is not evidence. Inspect:

1. the real target file;
2. `git status` and the complete `git diff`;
3. `git diff --check`;
4. removal of `{{TARGET_REPO}}/.grok/config.toml` and, if Keeper created it, the
   now-empty `.grok` directory;
5. the portable `operational/verify.sh` with the target repository path;
6. project-specific verifier output.

Reject and restore any out-of-scope file change. Report the outcome only as
`Track-D operational smoke`. Do not stage, commit, push, open a product PR,
merge, deploy, publish, or start ACP.

The portable verifier covers tracked and untracked Git state. It does not prove
that ignored paths were immutable; record that residual in readiness and inspect
any run-local ignored configuration before and after the call.
