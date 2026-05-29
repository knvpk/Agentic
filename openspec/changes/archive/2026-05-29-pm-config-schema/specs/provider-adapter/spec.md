## ADDED Requirements

### Requirement: Init Step 5 references config.schema.json rather than enumerating fields inline
The `init` mode Step 5 in SKILL.md SHALL replace the inline YAML example block with a reference to `config.schema.json` as the canonical field definition. The step description SHALL state: "Write `.project/config.yaml` conforming to `references/config.schema.json`."

#### Scenario: SKILL.md Step 5 contains no standalone field enumeration
- **WHEN** SKILL.md init Step 5 is read
- **THEN** it references `config.schema.json` for field definitions and does not duplicate the full field list inline
