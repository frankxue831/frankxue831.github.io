# Non-Live Grok Command Template

Status: `TEMPLATE ONLY / NOT AUTHORIZED`

This is the reviewed CLI shape for the fixed `gm-crypto-rs-demo` metadata task.
It is not a wrapper, executable script, or live-call authorization. Replace every
`{{...}}` cell, save the fully expanded command as a fresh attempt evidence file,
prove that no placeholder remains in that rendered file, and show it in the
one-page readiness before requesting fresh Product Owner approval. The source
template is expected to retain placeholders and is not scanned by that gate.

The 180-second wall limit belongs to the Codex execution tool. Do not add
`ulimit -f`, `RLIMIT_FSIZE`, or another process-wide file-size limit.

## Required project plugin configuration

Before any Grok process, Keeper requires
`{{TARGET_REPO}}/.grok/config.toml` to be absent, creates the parent directory if
needed, and copies `plugin-config.toml` there without changing its bytes. The
runtime file must be regular, non-symlink, and SHA-256
`679a6066749bce97740a109f243279d7dc873b2fbae248c2014bcf1954e2c03f`.
Grok auto-discovers this project config from `--cwd`.

Run this exact offline preflight shape before readiness:

```bash
/usr/bin/env \
  -u XAI_API_KEY \
  -u GROK_AUTH \
  GROK_DISABLE_AUTOUPDATER=1 \
  GROK_TELEMETRY_ENABLED=0 \
  GROK_TELEMETRY_TRACE_UPLOAD=0 \
  GROK_MEMORY=0 \
  GROK_SUBAGENTS=0 \
  GROK_WORKFLOWS=0 \
  GROK_WEB_FETCH=0 \
  GROK_CLAUDE_SKILLS_ENABLED=0 \
  GROK_CLAUDE_RULES_ENABLED=0 \
  GROK_CLAUDE_AGENTS_ENABLED=0 \
  GROK_CLAUDE_MCPS_ENABLED=0 \
  GROK_CLAUDE_HOOKS_ENABLED=0 \
  GROK_CURSOR_SKILLS_ENABLED=0 \
  GROK_CURSOR_RULES_ENABLED=0 \
  GROK_CURSOR_AGENTS_ENABLED=0 \
  GROK_CURSOR_MCPS_ENABLED=0 \
  GROK_CURSOR_HOOKS_ENABLED=0 \
  "{{GROK_BIN}}" \
  --no-auto-update \
  --cwd "{{TARGET_REPO}}" \
  inspect \
  --json
```

Retain its JSON. Stop unless Keeper verifies that `superpowers` is disabled,
there are no active hooks or MCPs, and no unexpected plugin skill/tool surface
remains. If the inspect schema or reported sources differ, stop rather than
guessing. This inspect call is offline configuration discovery, not a worker or
model call.

```bash
/usr/bin/env \
  -u XAI_API_KEY \
  -u GROK_AUTH \
  GROK_DISABLE_AUTOUPDATER=1 \
  GROK_TELEMETRY_ENABLED=0 \
  GROK_TELEMETRY_TRACE_UPLOAD=0 \
  GROK_MEMORY=0 \
  GROK_SUBAGENTS=0 \
  GROK_WORKFLOWS=0 \
  GROK_WEB_FETCH=0 \
  GROK_CLAUDE_SKILLS_ENABLED=0 \
  GROK_CLAUDE_RULES_ENABLED=0 \
  GROK_CLAUDE_AGENTS_ENABLED=0 \
  GROK_CLAUDE_MCPS_ENABLED=0 \
  GROK_CLAUDE_HOOKS_ENABLED=0 \
  GROK_CURSOR_SKILLS_ENABLED=0 \
  GROK_CURSOR_RULES_ENABLED=0 \
  GROK_CURSOR_AGENTS_ENABLED=0 \
  GROK_CURSOR_MCPS_ENABLED=0 \
  GROK_CURSOR_HOOKS_ENABLED=0 \
  "{{GROK_BIN}}" \
  --no-auto-update \
  --cwd "{{TARGET_REPO}}" \
  --sandbox strict \
  --model grok-4.5 \
  --effort low \
  --permission-mode dontAsk \
  --allow "Edit({{TARGET_REPO}}/Cargo.toml)" \
  --tools read_file,search_replace \
  --disallowed-tools run_terminal_cmd,web_search,web_fetch,Agent,task,get_task_output,kill_task,memory_search,memory_get,enter_plan_mode,exit_plan_mode,todo_write,workflow,update_goal,ask_user_question,skill,search_tool,use_tool \
  --no-subagents \
  --no-memory \
  --no-plan \
  --disable-web-search \
  --max-turns 3 \
  --output-format json \
  --json-schema '{"type":"object","additionalProperties":false,"required":["status","summary"],"properties":{"status":{"type":"string","enum":["candidate_diff_written","blocked"]},"summary":{"type":"string","maxLength":600}}}' \
  --verbatim \
  --prompt-file "{{PACKET_PATH}}"
```

## Constraint mapping

| Required constraint | Enforcing cells |
|---|---|
| Subscription session, not API key | `env -u XAI_API_KEY -u GROK_AUTH` and the already logged-in Grok home |
| Fixed repo/CWD | `--cwd {{TARGET_REPO}}` |
| One writable target | `--allow Edit({{TARGET_REPO}}/Cargo.toml)` plus post-run Git verification |
| Sole worker tools | `--tools read_file,search_replace` |
| No shell/web/meta tools | full `--disallowed-tools` list, `--disable-web-search`, and compatibility env flags |
| No subagents/memory/plan | `--no-subagents`, `--no-memory`, `--no-plan` plus matching env flags |
| Fixed model/budget | `--model grok-4.5`, `--effort low`, `--max-turns 3`, Codex timeout 180 seconds |
| Bounded final response | exact JSON schema with a 600-character summary maximum |
| No plugin hook shell | required `{{TARGET_REPO}}/.grok/config.toml`, offline inspect evidence, and Claude/Cursor hook env flags |

`dontAsk` makes the exact permission and tool lists safety-critical. The next
agent must inspect the local Grok 1.0.0 help/config state offline and stop if any
listed flag or tool ID no longer matches. The plugin config is Keeper-owned,
temporary run configuration; remove the file after Grok exits and remove the
`.grok` directory only if Keeper created it and it is empty. Prove the path is
absent before final repository verification.

Residual risk: the verifier proves tracked and untracked Git scope but not
ignored-path immutability. Record that limitation in readiness.
