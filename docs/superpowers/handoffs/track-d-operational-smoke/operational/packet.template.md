# Track-D Operational Smoke Packet Template

smoke_id: `{{FRESH_SMOKE_ID}}`

label: `Track-D operational smoke`

research_observation: `false`

lived2_instrument: `false`

live_authority: `requires fresh Product Owner approval`

## Fixed binding

- Repository: `https://github.com/frankxue831/gm-crypto-rs-demo.git`
- Working directory: `{{TARGET_REPO}}`
- Branch: `{{EXPECTED_BRANCH}}`
- HEAD: `{{EXPECTED_HEAD}}`
- Model: `grok-4.5`
- Reasoning effort: `low`
- Maximum turns: `3`
- Wall timeout: `180 seconds`
- Final summary: at most `600 characters`
- Output schema:
  `{"type":"object","additionalProperties":false,"required":["status","summary"],"properties":{"status":{"type":"string","enum":["candidate_diff_written","blocked"]},"summary":{"type":"string","maxLength":600}}}`
- Sole writable target: `Cargo.toml`
- Target SHA-256 before: `{{TARGET_SHA256_BEFORE}}`
- Expected target SHA-256 after: `{{TARGET_SHA256_AFTER}}`
- Allowed tools: `read_file,search_replace`
- Disabled surfaces: shell, web, subagents, memory, plan, skills, workflows,
  goal/todo, and all other MCP/meta-tools.

## Task

The package description in `Cargo.toml` says this downstream demo covers the
`gmcrypto-core` SM2/SM3 crate. The repository's README capability map and current
examples also cover SM4. Make the package metadata accurate with exactly this
one-line replacement.

Old:

```toml
description = "Downstream crates.io smoke-test demo for the gmcrypto-core SM2/SM3 crate"
```

New:

```toml
description = "Downstream crates.io smoke-test demo for the gmcrypto-core SM2/SM3/SM4 crate"
```

## Worker constraints

1. Read `Cargo.toml` before editing it.
2. Use `search_replace` once to make the exact replacement above.
3. Do not edit or create any other file.
4. Do not change dependencies, features, version, formatting, or surrounding text.
5. Do not run tests or commands; Codex owns verification.
6. Stop immediately after the candidate edit. Your summary is not evidence.

Return status `candidate_diff_written` only if the exact replacement was made.
Otherwise return status `blocked` without trying an alternative edit.

Before readiness, render this template and the command template into fresh
attempt evidence files. `rg -n '\{\{[^}]+\}\}' <rendered-packet>
<rendered-command>` must find no unresolved placeholders in those rendered
artifacts. Do not scan the source templates themselves. If the bound commit or
task changed, stop and write a new task-specific packet/verifier rather than
weakening this one.
