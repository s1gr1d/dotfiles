# Shell aliases

# Package managers
alias ni='npm install'
alias nb='npm run build'

alias yi='yarn install'
alias yb='yarn build'
alias ybd='yarn build:dev'
alias ybt='yarn build:tarball'

alias pi='pnpm install'
alias pb='pnpm build'

# yalc (local package linking)
alias yalc:p='yarn yalc:publish'
alias yalc:u='yalc update'

# Navigation / app shortcuts
alias cd:sentry='cd /Users/sigridh/Documents/DEV/Sentry-dev/code/sentry'
alias cd:sdk-js='cd /Users/sigridh/Documents/DEV/sentry-javascript'
alias webstorm="open -b com.jetbrains.webstorm"

# Git repo-insight one-liners
alias git:most-changed='git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20'
alias git:bug-cluster='git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20'
alias git:contrib-commits='git shortlog -sn --no-merges'
alias git:monthly-commits='git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c'
alias git:hotfix-frequency='git log --oneline --since="1 year ago" | grep -iE "revert|hotfix|emergency|rollback"'
