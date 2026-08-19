# 🍭 dotfiles and config

My personal dotfiles: shell config and a vendor-neutral setup for AI coding
agents (Claude Code, Codex, …). The repo is the single source of truth —
everything else is a symlink pointing back here, so editing a file in this repo
updates it everywhere at once.

## Preferences

- **Shell:** zsh with Oh My Zsh
- **Terminal:** kitty (cross-platform)
- **Editors:** Nano (quick edits), Neovim (someday), CotEditor (macOS GUI)
- **Theme:** catppuccin in kitty
- **Fonts:** Recursive Mono Linear, Fira Code

## Structure

```
dotfiles/
├── install.sh              # symlinks everything into place (idempotent)
├── shell/
│   ├── zshrc               # thin: Oh My Zsh setup + sources the modules below
│   └── zsh/                # split so each concern is small and greppable
│       ├── exports.zsh     # environment variables
│       ├── tools.zsh       # PATH entries, tool hooks (Volta, bun, direnv, …)
│       ├── aliases.zsh     # shell aliases
│       └── functions.zsh   # shell functions (pp, prs-to-review, …)
└── agents/                 # cross-agent config — see agents/README.md
    ├── AGENTS.md           # global instructions, shared by Claude Code + Codex
    ├── prompts/            # paste-on-demand snippets, invoked via the `pp` function
    └── skills/             # auto-loaded task instructions (SKILL.md folders)
```

## Setup on a new machine

1. **Clone the repo** anywhere — the paths are not hard-coded, `install.sh`
   figures out where it lives:

   ```sh
   git clone <this-repo> ~/dotfiles && cd ~/dotfiles
   ```

2. **Preview what will change** (nothing is written yet):

   ```sh
   ./install.sh --dry-run
   ```

3. **Create the symlinks:**

   ```sh
   ./install.sh
   ```

   It backs up anything already at a target to `<file>.bak` before linking, and
   is safe to re-run. Links it creates:

   | Symlink | Points at | Used by |
   |---|---|---|
   | `~/.zshrc` | `shell/zshrc` | zsh (sources `shell/zsh/*.zsh`) |
   | `~/.prompts` | `agents/prompts` | the `pp` shell function |
   | `~/.claude/skills` | `agents/skills` | Claude Code |
   | `~/.claude/CLAUDE.md` | `agents/AGENTS.md` | Claude Code |
   | `~/.codex/AGENTS.md` | `agents/AGENTS.md` | Codex |

4. **Reload the shell:** open a new terminal (or `source ~/.zshrc`).

5. **Install the rest by hand** (not managed here, see notes below):
   - Oh My Zsh + the zsh plugins listed in `shell/zshrc`
   - Any Claude Code plugin marketplaces you use (e.g. `sentry-skills`)

## How it works & why

- **One source of truth, many symlinks.** Each tool reads config from a fixed
  location (`~/.zshrc`, `~/.claude/skills`, …). Instead of copying files there,
  we symlink those locations back to this repo. Edit once, and every tool sees
  the change — no sync step. This is the standard dotfiles pattern.

- **`AGENTS.md`, written once.** `AGENTS.md` is an open, cross-agent standard for
  project/global instructions, read natively by Codex and many others
  ([agents.md](https://agents.md/)). Claude Code's own file is `CLAUDE.md`, so we
  point `~/.claude/CLAUDE.md` at the same `AGENTS.md` — one file feeds both.

- **`skills/` vs `prompts/`.** Skills are structured `SKILL.md` folders an agent
  *auto-loads* when a task matches their `description`; prompts are snippets *you*
  paste on demand via `pp` (e.g. `pp personal/coding-style`). See
  [`agents/README.md`](agents/README.md) for the details.

- **Shell config is split by concern.** The 300-line `.zshrc` became a thin
  entry point that sources `shell/zsh/*.zsh` in order (exports → tools → aliases
  → functions). Interdependent lines (e.g. a tool's env var and its `PATH`
  entry) stay together in the same file.

- **What this repo does *not* manage:** Claude Code plugin/marketplace skills
  live under `~/.claude/plugins/` and are managed by Claude Code itself — don't
  symlink those. This repo only owns skills you author in `agents/skills/`.

### Reference docs

- AGENTS.md standard — <https://agents.md/>
- Claude Code docs — <https://code.claude.com/docs>
  - Skills — <https://code.claude.com/docs/en/skills>
  - Memory / CLAUDE.md — <https://code.claude.com/docs/en/memory>
- OpenAI Codex CLI — <https://learn.chatgpt.com/docs/codex/cli>
