# agents/

Personal, cross-agent config kept under version control. One source of truth
here; each tool gets a symlink into the path it expects.

- **`AGENTS.md`** — global instructions (style, conventions, habits) that apply
  everywhere. Consumed by Codex natively and by Claude Code via a `CLAUDE.md`
  symlink, so it's written once.
- **`skills/`** — auto-loaded structured task instructions (Agent Skills
  open-standard `SKILL.md` format). An agent reads each skill's frontmatter
  `description` and loads it when the task matches. One skill = one task.
- **`prompts/`** — paste-on-demand snippets, invoked via the `pp` shell
  function, e.g. `pp personal/coding-style`. The `personal/` namespace is
  load-bearing for `pp` — keep it.

## Wiring it up

The repo-root `install.sh` symlinks everything (shell config + this agents
area) into place. Run it once per machine — it derives its own path, backs up
anything already at a target, and is safe to re-run:

```sh
../install.sh
```

Agent links it creates (see `install.sh` for the shell links too):

| Target | Source |
|---|---|
| `~/.prompts` | `agents/prompts` |
| `~/.claude/skills` | `agents/skills` |
| `~/.claude/CLAUDE.md` | `agents/AGENTS.md` |
| `~/.codex/AGENTS.md` | `agents/AGENTS.md` |

## Notes

- **Formats are stable, locations drift.** `SKILL.md` and `AGENTS.md` as file
  formats are broadly adopted, but the exact directory each tool scans changes
  between releases. If a link stops being picked up, check that tool's current
  docs and adjust `install.sh`.
- Claude Code's native global instruction file is `CLAUDE.md`, not `AGENTS.md`,
  which is why the installer points `CLAUDE.md` at `AGENTS.md` — one file, both
  agents.
- Keep `AGENTS.md` short and specific. It loads every turn, so verbosity costs
  context. Put repo-specific facts (build/test commands) in each project's own
  `AGENTS.md`, not here.
