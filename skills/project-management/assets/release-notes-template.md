## {{header}}

**Range**: {{previous_tag_or_ref}} → {{current_tag}}
**Tickets**: {{total_resolved}} resolved

{{#each label_groups}}
### {{name}} ({{count}} ticket{{#if plural}}s{{/if}})
{{#each tickets}}
- {{id}}: {{title}}
{{/each}}

{{/each}}
{{#if unlabelled_tickets}}
### Unlabelled ({{unlabelled_count}} ticket{{#if unlabelled_plural}}s{{/if}})
{{#each unlabelled_tickets}}
- {{id}}: {{title}}
{{/each}}

{{/if}}
{{#if other_commits}}
### Other
{{#each other_commits}}
- {{subject}}
{{/each}}
{{/if}}
{{#if spec_changes}}
---

### Spec Changes

{{#each spec_changes}}
**{{capability}}**
{{#each summary_lines}}
- {{this}}
{{/each}}

{{/each}}
{{/if}}
