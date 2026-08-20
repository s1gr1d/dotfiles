# 🍭 dotfiles and config

My dotfiles: shell config plus a vendor-neutral setup for AI coding agents like
Claude Code and Codex. This repo is the source of truth. Everything else is a
symlink pointing back here, so editing a file in the repo updates it everywhere
at once.

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
│   ├── zshrc               # thin entry point; sources the modules below
│   └── zsh/                # split so each concern is small and greppable
│       ├── exports.zsh     # environment variables
│       ├── tools.zsh       # PATH entries and tool hooks (Volta, bun, direnv)
│       ├── aliases.zsh     # shell aliases
│       └── functions.zsh   # shell functions like pp and prs-to-review
└── agents/                 # cross-agent config; see agents/README.md
    ├── AGENTS.md           # global instructions, shared by Claude Code and Codex
    ├── prompts/            # paste-on-demand snippets, invoked via the `pp` function
    └── skills/             # auto-loaded task instructions (SKILL.md folders)
```

## Setup on a new machine

1. Clone the repo anywhere. The paths are not hard-coded, so `install.sh` finds
   where it lives:

   ```sh
   git clone <this-repo> ~/dotfiles && cd ~/dotfiles
   ```

2. Preview the changes. Nothing is written yet:

   ```sh
   ./install.sh --dry-run
   ```

3. Create the symlinks:

   ```sh
   ./install.sh
   ```

   It backs up anything already at a target to `<file>.bak` before linking, and
   you can re-run it safely. It creates these links:

   | Symlink               | Points at          | Used by                         |
   |-----------------------|--------------------|---------------------------------|
   | `~/.zshrc`            | `shell/zshrc`      | zsh (sources `shell/zsh/*.zsh`) |
   | `~/.prompts`          | `agents/prompts`   | the `pp` shell function         |
   | `~/.claude/skills`    | `agents/skills`    | Claude Code                     |
   | `~/.claude/CLAUDE.md` | `agents/AGENTS.md` | Claude Code                     |
   | `~/.codex/AGENTS.md`  | `agents/AGENTS.md` | Codex                           |

4. Reload the shell. Open a new terminal, or run `source ~/.zshrc`.

5. Install the rest by hand. This repo does not manage:
   - Oh My Zsh and the zsh plugins listed in `shell/zshrc`
   - Any Claude Code plugin marketplaces you use, such as `sentry-skills`

## How it works and why

One source of truth, many symlinks. Each tool reads its config from a fixed
location like `~/.zshrc` or `~/.claude/skills`. Instead of copying files there,
the installer symlinks those locations back to this repo. You edit once and
every tool sees the change, with no sync step. This is the standard dotfiles
pattern.

`AGENTS.md`, written once. It is an open cross-agent standard for global and
project instructions that Codex and many other tools read directly
([agents.md](https://agents.md/)). Claude Code uses `CLAUDE.md` instead, so the
installer points `~/.claude/CLAUDE.md` at the same `AGENTS.md`. One file feeds
both.

`skills/` vs `prompts/`. Skills are `SKILL.md` folders an agent loads on its own
when a task matches the `description`. Prompts are snippets you paste yourself
with `pp`, for example `pp personal/coding-style`. See
[`agents/README.md`](agents/README.md) for more.

Shell config split by concern. The old 300-line `.zshrc` is now a thin entry
point that sources `shell/zsh/*.zsh` in this order: exports, tools, aliases,
functions. Lines that depend on each other, like a tool's env var and its `PATH`
entry, stay in the same file.

What this repo does not manage. Claude Code marketplace skills live under
`~/.claude/plugins/`, and Claude Code manages them itself, so don't symlink
those. This repo owns only the skills you write in `agents/skills/`.

### Reference docs

- AGENTS.md standard: <https://agents.md/>
- Claude Code docs: <https://code.claude.com/docs>
  - Skills: <https://code.claude.com/docs/en/skills>
  - Memory and CLAUDE.md: <https://code.claude.com/docs/en/memory>
- OpenAI Codex CLI: <https://learn.chatgpt.com/docs/codex/cli>
