# provider-routing

## Purpose

TBD — This capability was superseded during implementation. See note below.

> **Superseded** — The provider system (config key, tool-name mapping table, `providers/` fragment files, `CLAUDE.md`/`AGENTS.md` emission) was removed during implementation at user direction. The skill is provider-agnostic: it describes operations without naming specific tools, and relies on the LLM's native knowledge of its own environment. All requirements below are intentionally not implemented.

---

## Requirements

### Requirement: Provider is declared in config and read at startup
The skill SHALL read `provider` from `vibe_wiki.config.yaml` at startup. Valid values are `claude-code` and `codex`. If absent or invalid, the skill SHALL halt and prompt the user to set it before proceeding.

#### Scenario: Valid provider in config
- **WHEN** `provider: claude-code` or `provider: codex` is present in config
- **THEN** the skill loads the corresponding tool name mappings and continues startup

#### Scenario: Provider key absent
- **WHEN** `provider` key is missing from `vibe_wiki.config.yaml`
- **THEN** the skill halts, explains the key is required, and shows the two valid values

### Requirement: Tool names are mapped per provider
All file and web operations in SKILL.md SHALL reference abstract operation names (e.g., `read_file`, `write_file`, `fetch_url`, `search_web`). The startup routine SHALL resolve these to provider-specific tool names before any operation executes.

### Requirement: Provider schema fragments are separate files
The wiki schema document content specific to each provider SHALL live in `providers/claude-code.md` and `providers/codex.md` as standalone fragments. SKILL.md SHALL reference these by path; `wiki init` SHALL compose the final schema doc from the appropriate fragment.
