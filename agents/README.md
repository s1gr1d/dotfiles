# agents/

Personal, cross-agent config kept under version control. One source of truth
here; each tool gets a symlink into the path it expects.

- **`AGENTS.md`** — global instructions (style, conventions, habits) that apply
  everywhere. Consumed by Codex natively and by Claude Code via a `CLAUDE.md`
  symlink, so it's written once.
- **`skills/`** — auto-loaded structured task instructions (Agent Skills
  open-standard `SKILL.md` format). An agent reads each skill's frontmatter
  `description` and loads it when the task matches. One skill = one task. Holds
  both hand-written skills and vendored ones (see Vendored skills below).
- **`prompts/`** — paste-on-demand snippets, invoked via the `pp` shell
  function, e.g. `pp personal/coding-style`. The `personal/` namespace is
  load-bearing for `pp` — keep it.

## Vendored skills

### pstack

Source: https://github.com/cursor/plugins/tree/main/pstack/skills

- [principle-fix-root-causes](skills/principle-fix-root-causes)
- [principle-foundational-thinking](skills/principle-foundational-thinking)
- [principle-guard-the-context-window](skills/principle-guard-the-context-window)
- [principle-laziness-protocol](skills/principle-laziness-protocol)
- [technical-writing](skills/technical-writing)
- [unslop](skills/unslop)


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
