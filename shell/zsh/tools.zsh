# Tool integrations: PATH entries, shell hooks, and completions

# Volta (JS toolchain manager)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export VOLTA_FEATURE_PNPM=1 # enable pnpm in Volta

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun" # bun completions

# Sentry devenv toolchain + direnv
export PATH="$HOME/.local/share/sentry-devenv/bin:$PATH"
eval "$(direnv hook zsh)"
export PYTHON=3.11

# Local bin environment (installer-managed, e.g. uv)
. "$HOME/.local/bin/env"
