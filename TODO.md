## TODO

- [ ] Ensure labels created by `project-management` is scoped to project or group.
- [x] In `project-management` skill `docs` command it just copied the tools and api file, but it should be interactive to ask questions and fill them actaully, and not scoped to only those mentioned
- [ ] Health check recommendation in `api.md`
- [ ] Ability to get the `docs/` from different repo.
- [ ] Perspective of `project-management` skill is for "single-man-army"
- [ ] In `project-management` skill `next` command should support "no of tickets" to do so that claude can utilize `claude agents` and do things paralelly.
- [ ] Does `.project/config.yaml` support ENV params to fill `GITLAB_URL` in case of self-hosted gitlab env.
- [x] Gitlab doesnt support native sprints, that also needs to be done by labels only. The IssueBoard is confusing item its just a board filtered by labels.
- [x] Project managment skill should follow agile practises.
- [x] Giltab mcp doesnt have update_issue tool to change the status.
- [ ] A dedicated .env.tempalte skill. as part of engineering group. which should be gitlable.
- [x] Branching strategy should be part of config.yaml
- [ ] After ospx archive it should detect if there are any new changes did, it should comment on the gitlab issue. Also possible new changes concluded in explore session should update tickets as well.
- [x] In `project-management` skill add `help` command.