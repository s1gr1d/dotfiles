# .agents/

Project-local agent config scoped to this repo.


Claude Code reads project skills from `.claude/skills/`, so that's a relative symlink:

```
.claude/skills -> ../.agents/skills
```
