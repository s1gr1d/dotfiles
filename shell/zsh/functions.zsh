# Shell functions

# Install a locally-built Sentry SDK tarball with the given package manager
install-js-tgz() {
  local pm="$1"
  local pkg="$2"

  [[ -n "$pm" && -n "$pkg" ]] || { echo "Usage: install-js-tgz <npm|yarn|pnpm|bun> <package-name> [version]"; return 1 }

  # Modify sentry-javascript path as needed
  local sdk_dir="/Users/sigridh/Documents/DEV/sentry-javascript/packages"
  local pkg_dir="$sdk_dir/$pkg"
  [[ -d "$pkg_dir" ]] || { echo "Package directory not found: $pkg_dir"; return 1 }

  local tarball
  if [[ -n "$3" ]]; then
    tarball="$pkg_dir/sentry-${pkg}-${3}.tgz"
    [[ -f "$tarball" ]] || { echo "Version $3 not found for $pkg"; return 1 }
  else
    # If no version is specified, search for the latest version
    tarball=$(ls -t "$pkg_dir"/sentry-${pkg}-*.tgz 2>/dev/null | head -1)
    [[ -n "$tarball" ]] || { echo "No tarballs found for $pkg"; return 1 }
  fi

  echo "Installing $tarball..."
  case "$pm" in
    npm)  npm install "$tarball" ;;
    yarn) yarn add "$tarball" ;;
    pnpm) pnpm add "$tarball" ;;
    bun)  bun add "$tarball" ;;
    *) echo "Unknown package manager: $pm. Use npm, yarn, pnpm, or bun."; return 1 ;;
  esac
}

# Inject a named prompt snippet into clipboard or stdout (pp = paste-prompt)
pp() {
  local snippet="$HOME/.prompts/$1.md"
  if [[ -f "$snippet" ]]; then
    cat "$snippet" | pbcopy  # or xclip on Linux
    echo "Copied: $1"
  else
    echo "Not found: $snippet"
    ls ~/.prompts/
  fi
}

# ---- prs-to-review: open PRs awaiting your review ----
# Usage: prs-to-review [ORG] [-n N] [--no-color] [--plain-url]
#   PR numbers are clickable (OSC 8 hyperlinks). --plain-url adds a full URL
#   column instead, for terminals without OSC 8 support.
#   Requires: gh (authenticated), jq, awk.
prs-to-review() {
  emulate -L zsh
  setopt local_options pipe_fail no_unset

  local ORG="getsentry" LIMIT=50 COLOR=1 PLAINURL=0
  while (( $# )); do
    case "$1" in
      -n|--limit)
        [[ "${2-}" == <-> ]] || { print -u2 "prs-to-review: $1 needs a number"; return 2; }
        LIMIT="$2"; shift 2 ;;
      --no-color)  COLOR=0; shift ;;
      --plain-url) PLAINURL=1; shift ;;
      -h|--help)
        print "Usage: prs-to-review [ORG] [-n N] [--no-color] [--plain-url]"; return 0 ;;
      -*) print -u2 "prs-to-review: unknown option $1"; return 2 ;;
      *)  ORG="$1"; shift ;;
    esac
  done
  (( LIMIT > 100 )) && LIMIT=100          # GraphQL search returns at most 100/page

  local dep
  for dep in gh jq awk; do
    command -v "$dep" >/dev/null || { print -u2 "prs-to-review: '$dep' not found"; return 1; }
  done

  # Color only when stdout is a terminal and not disabled.
  local B="" R="" G="" Y=""
  if (( COLOR )) && [[ -t 1 ]]; then
    B=$'\e[1m'; R=$'\e[0m'; G=$'\e[32m'; Y=$'\e[33m'
  fi

  local me data
  me="$(GH_PAGER=cat gh api user --jq .login 2>/dev/null </dev/null)" \
    || { print -u2 "prs-to-review: not authenticated (run 'gh auth login')"; return 1; }
  data="$(GH_PAGER=cat gh api graphql \
      -f q="is:open is:pr user-review-requested:@me user:${ORG}" \
      -F n="$LIMIT" \
      -f query='query($q:String!,$n:Int!){
        search(query:$q, type:ISSUE, first:$n){ nodes{ ... on PullRequest{
          number title additions deletions createdAt url
          repository{ name }
          reviews(first:100){ nodes{ state author{ login } } }
        }}}}' </dev/null)" \
    || { print -u2 "prs-to-review: GitHub query failed"; return 1; }

  local count
  count="$(jq '.data.search.nodes | length' <<<"$data")" || return 1
  if (( count == 0 )); then
    print "No PRs awaiting your review in ${ORG}."
    return 0
  fi

  # jq emits plain TSV (no escapes) so awk can measure real column widths.
  # Column 1 carries "#<n>\u0001<url>"; the \u0001 marker lets awk attach an
  # OSC 8 hyperlink after width is computed. Fields:
  #   NUM  REPO  TITLE  AGE  LINES  REVIEWED  [URL]
  local rows
  rows="$(jq -r --arg me "$me" --argjson plain "$PLAINURL" '
    def age($t): (now - ($t|fromdate)) as $s
      | if   $s < 3600  then "\($s/60    |floor)m"
        elif $s < 86400 then "\($s/3600  |floor)h"
        else                 "\($s/86400 |floor)d" end;
    .data.search.nodes[]
    | ([.reviews.nodes[]
        | select(.state != "PENDING" and .author.login != $me)] | length > 0) as $rev
    | (if (.title|length) > 50 then .title[:47] + "..." else .title end) as $title
    | ("#\(.number)" + (if $plain==1 then "" else "\u0001\(.url)" end)) as $num
    | [ $num, .repository.name, $title, age(.createdAt),
        "+\(.additions)/-\(.deletions)", (if $rev then "yes" else "no" end) ]
      + (if $plain==1 then [.url] else [] end)
    | @tsv' <<<"$data")" || return 1

  local header='#	REPO	TITLE	AGE	LINES	REVIEWED BY OTHERS'
  (( PLAINURL )) && header+=$'\tURL'

  print -- "${B}PRs awaiting your review — ${ORG} (${count})${R}"
  print

  # Single awk pass: compute widths from visible text, then render padded cells,
  # applying the OSC 8 link (col 1) and color (last col) only to output cells.
  # No re-parsing of pre-aligned text, so titles containing "yes"/"no" are safe.
  { print -r -- "$header"; print -r -- "$rows"; } \
  | awk -F'\t' -v G="$G" -v Y="$Y" -v R="$R" '
      function vis(s,   i){ i=index(s,"\001"); return (i>0)?substr(s,1,i-1):s }
      {
        for (c=1; c<=NF; c++) {
          cell[NR,c] = $c
          v = (c==1) ? vis($c) : $c
          if (length(v) > w[c]) w[c] = length(v)
        }
        if (NF > ncol) ncol = NF
        nrow = NR
      }
      END {
        for (r=1; r<=nrow; r++) {
          line = ""
          for (c=1; c<=ncol; c++) {
            raw = cell[r,c]
            if (c==1 && r>1) {
              i = index(raw,"\001")
              num = (i>0)?substr(raw,1,i-1):raw
              url = (i>0)?substr(raw,i+1):""
              disp = (url!="") ? ("\033]8;;" url "\007" num "\033]8;;\007") : num
              pad = w[c] - length(num)
            } else if (c==ncol && r>1 && (raw=="yes"||raw=="no")) {
              disp = ((raw=="yes")?G:Y) raw R
              pad = w[c] - length(raw)
            } else {
              disp = raw
              pad = w[c] - length(raw)
            }
            line = line disp
            if (c < ncol) line = line sprintf("%*s", pad, "") "  "
          }
          print line
        }
      }'
}
