# Track D Handoff Publication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a self-contained, sanitized Track D handoff on an isolated branch and draft pull request.

**Architecture:** Keep current operational-smoke guidance in one handoff directory, with the failed first attempt and next-agent instructions beside portable packet and a fixed task-specific verifier. Preserve v2.1-B only as a sanitized historical archive whose original local hashes are recorded; do not install it at active instrument paths.

**Tech Stack:** Markdown, zsh, Git, SHA-256, Jekyll repository validation.

## Global Constraints

- Label the work only as `Track-D operational smoke`; never use RepoLens research-observation or LiveD2 instrument labels.
- Treat v2.1-B as frozen research-grade envelope exploration, not an execution gate or daily-work prerequisite.
- Publish no credentials, session state, global Grok logs, private Notion page identifiers, or personal absolute paths.
- Do not call Grok/xAI, stage product code, merge, deploy, publish the site, or start ACP.
- Use a fresh worktree and the branch `codex/track-d-handoff-2026-08-09` from current `origin/main`.

---

### Task 1: Build the operational-smoke handoff

**Files:**
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/README.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/DECISION.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/NEXT_AGENT.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/operational/packet.template.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/operational/command.template.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/operational/verify.sh`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/operational/plugin-config.toml`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/operational/attempt-01/RESULT.md`

**Interfaces:**
- Consumes: the PO freeze/operational-smoke decision and the retained attempt-01 facts.
- Produces: a portable start-here path and a parameterized independent verifier.

- [x] **Step 1: Write and run a failing verifier acceptance check**

Run an external temporary check that requires the not-yet-created executable to expose `Usage: verify.sh TARGET_REPO`.

- [x] **Step 2: Write the minimal portable verifier**

Accept the target repository as the sole argument, keep expected repository facts as immutable literals, and independently prove the one-file/one-line diff plus Rust project checks.

- [x] **Step 3: Write the decision, result, packet, and next-agent records**

Keep the repository handoff self-contained and state that the consumed live authorization does not carry forward.

- [x] **Step 4: Run verifier acceptance checks**

Verify help and syntax, prove rejection on the unchanged target, and prove acceptance on a temporary exact-edit copy.

### Task 2: Preserve v2.1-B as a non-executable archive

**Files:**
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/README.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/design.sanitized.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/qualification-plan.sanitized.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/instrument-readme.md`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/precommit.json`
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/archive/v2.1b/red-harness.sanitized.zsh`

**Interfaces:**
- Consumes: five frozen local v2.1-B artifacts and their verified source SHA-256 values.
- Produces: readable historical context without active-path installation or machine-private identifiers.

- [x] **Step 1: Copy the five frozen artifacts into the archive namespace**

Do not modify or remove the dirty historical worktree.

- [x] **Step 2: Apply only mechanical privacy substitutions**

Replace personal absolute paths and private Notion URLs with explicit placeholders. Preserve original source hashes in the archive README and state that derivative hashes intentionally differ.

- [x] **Step 3: Prove the archive is non-active**

Require the archive warning to state that the RED harness is intentionally incomplete and must not be executed as a qualification gate.

### Task 3: Verify and publish the handoff

**Files:**
- Create: `docs/superpowers/handoffs/track-d-operational-smoke/manifest.sha256`
- Modify: `docs/superpowers/plans/2026-08-09-track-d-handoff-publication.md`

**Interfaces:**
- Consumes: every file produced by Tasks 1 and 2.
- Produces: one reviewed commit, pushed branch, and draft pull request.

- [x] **Step 1: Generate and check the explicit SHA-256 manifest**

The manifest covers every handoff payload and this plan, but excludes itself.

- [x] **Step 2: Scan for secrets and local-path leakage**

Reject credentials, private Notion identifiers, `/Users/...` paths, global Grok files, and unrelated temporary evidence.

- [x] **Step 3: Run repository checks**

Run `git diff --check`, `bundle exec jekyll build`, and `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 ruby scripts/validate_site.rb`.

- [x] **Step 4: Stage only explicit handoff paths and commit**

Use commit message `docs: hand off Track D operational smoke`.

- [x] **Step 5: Push and open a draft pull request**

Target `main`; do not merge or deploy.
