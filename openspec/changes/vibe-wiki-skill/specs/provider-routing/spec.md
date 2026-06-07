## ADDED Requirements

### Requirement: Provider is declared in config and read at startup
The skill SHALL read `provider` from `vibe_wiki.config.yaml` at startup. Valid values are `claude-code` and `codex`. If absent or invalid, the skill SHALL halt and prompt the user to set it before proceeding.

Affected files: `SKILL.md` (vibe_wiki), `assets/vibe_wiki.config.template.yaml` (new)

#### Scenario: Valid provider in config
- **WHEN** `provider: claude-code` or `provider: codex` is present in config
- **THEN** the skill loads the corresponding tool name mappings and continues startup

#### Scenario: Provider key absent
- **WHEN** `provider` key is missing from `vibe_wiki.config.yaml`
- **THEN** the skill halts, explains the key is required, and shows the two valid values

### Requirement: Tool names are mapped per provider
All file and web operations in SKILL.md SHALL reference abstract operation names (e.g., `read_file`, `write_file`, `fetch_url`, `search_web`). The startup routine SHALL resolve these to provider-specific tool names before any operation executes.

| Abstract op   | claude-code   | codex               |
|---------------|---------------|---------------------|
| `read_file`   | `Read`        | `file_search` / read via `code_interpreter` |
| `write_file`  | `Write`       | write via `code_interpreter` |
| `fetch_url`   | `WebFetch`    | `web_search`        |
| `search_web`  | `WebSearch`   | `web_search`        |
| `list_files`  | `Glob`        | `file_search`       |

Affected files: `SKILL.md` (vibe_wiki), `providers/claude-code.md`, `providers/codex.md`

#### Scenario: Claude Code tool resolution
- **WHEN** provider is `claude-code` and the skill needs to fetch a URL
- **THEN** it uses the `WebFetch` tool with the URL as argument

#### Scenario: Codex tool resolution
- **WHEN** provider is `codex` and the skill needs to fetch a URL
- **THEN** it uses `web_search` to retrieve the content

### Requirement: Provider schema fragments are separate files
The wiki schema document content specific to each provider SHALL live in `providers/claude-code.md` and `providers/codex.md` as standalone fragments. SKILL.md SHALL reference these by path; `wiki init` SHALL compose the final schema doc from the appropriate fragment.

Affected files: `providers/claude-code.md` (new), `providers/codex.md` (new), `SKILL.md` (vibe_wiki)

#### Scenario: Schema doc composition at init
- **WHEN** `wiki init` runs with `provider: claude-code`
- **THEN** it reads `providers/claude-code.md`, inserts the wiki structure preamble, and writes the result as `CLAUDE.md` in `wiki.root`
