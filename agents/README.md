# agents/

Personal, cross-agent config kept in version control. This folder is the source
of truth, and each tool gets a symlink into the path it expects.

- `AGENTS.md` holds global instructions (style, conventions, habits) for every
  project. Codex reads it directly. Claude Code reads it through a `CLAUDE.md`
  symlink, so you write it once.
- `skills/` holds structured task instructions in the open `SKILL.md` format. An
  agent reads each skill's `description` and loads the skill when the task
  matches. Keep one skill to one task. This folder mixes skills I wrote and
  skills I vendored (listed below).
- `prompts/` holds snippets you paste on demand with the `pp` shell function,
  for example `pp personal/coding-style`. The `pp` function depends on the
  `personal/` namespace, so keep it.

## Vendored skills

### pstack

Source: https://github.com/cursor/plugins/tree/main/pstack/skills

- [principle-encode-lessons-in-structure](skills/principle-encode-lessons-in-structure)
- [principle-experience-first](skills/principle-experience-first)
- [principle-fix-root-causes](skills/principle-fix-root-causes)
- [principle-foundational-thinking](skills/principle-foundational-thinking)
- [principle-guard-the-context-window](skills/principle-guard-the-context-window)
- [principle-laziness-protocol](skills/principle-laziness-protocol)
- [principle-subtract-before-you-add](skills/principle-subtract-before-you-add)
- [technical-writing](skills/technical-writing)
- [typescript-best-practices](skills/typescript-best-practices)
- [unslop](skills/unslop)

### mattpocock/skills

Source: https://github.com/mattpocock/skills

- [code-review](skills/code-review)
- [grilling](skills/grilling)
- [teach](skills/teach)
- [writing-for-agents](skills/writing-for-agents)

## Notes

- Formats are stable, but locations drift. The `SKILL.md` and `AGENTS.md`
  formats are widely adopted, yet the directory each tool scans changes between
  releases. If a link stops working, check the tool's current docs and adjust
  `install.sh`.
- Claude Code reads `CLAUDE.md`, not `AGENTS.md`. That is why the installer
  points `CLAUDE.md` at `AGENTS.md`, so both agents share one file.
- Keep `AGENTS.md` short and specific. It loads on every turn, so length costs
  context. Put repo-specific facts like build and test commands in each
  project's own `AGENTS.md`, not here.
