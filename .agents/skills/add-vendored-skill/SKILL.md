---
name: add-vendored-skill
description: Vendor an external agent skill into this dotfiles repo. Use when the user posts a GitHub link to a skill folder or file and wants it added under agents/skills/ and linked in agents/README.md.
---

# Add a vendored skill

Copy an external skill into `agents/skills/` byte-for-byte and register it in
`agents/README.md`. The user pastes a GitHub link to the skill.

## Rule: copy verbatim

Vendored files are checked in unmodified. Do not reformat, fix typos, rewrite
the `description`, or "improve" anything. If it needs changes, that is a
separate edit the user asks for after vendoring.

Fetch the raw bytes with `curl`/`gh` — not WebFetch, which converts pages to
lossy markdown.

## Steps

1. **List the whole skill folder — never trust the link alone.** A skill is the
   whole directory that holds `SKILL.md`, not one file. Even when the user pastes
   a `blob/.../SKILL.md` link, the folder almost always bundles siblings
   (`agents/openai.yaml`, `references/*.md`, `*-FORMAT.md`, scripts). Missing them
   silently breaks the skill. So always find the folder that holds the `SKILL.md`
   and list it recursively:
   ```bash
   gh api "repos/<owner>/<repo>/git/trees/<ref>?recursive=1" \
     --jq '.tree[] | select(.type=="blob" and (.path | startswith("<skill-folder>/"))) | .path'
   ```
   Quote the URL — the `?` glob-expands in zsh otherwise. Files download from
   `https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>`.

2. **Pick the skill name.** Use the source folder name (the directory that holds
   `SKILL.md`). It must be lowercase letters, numbers, and hyphens.

3. **Copy every file in, preserving structure.** Recreate each source path
   (including subdirs like `agents/` and `references/`) under
   `agents/skills/<name>/`. Loop over the paths from step 1:
   ```bash
   base="https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<skill-folder>"
   for f in SKILL.md agents/openai.yaml references/patterns.md; do
     mkdir -p "agents/skills/<name>/$(dirname "$f")"
     curl -fsSL "$base/$f" -o "agents/skills/<name>/$f"
   done
   ```

4. **Verify.** Confirm every source file landed (`find agents/skills/<name>
   -type f` matches the step 1 list) and `SKILL.md` frontmatter is intact.

5. **Register in `agents/README.md`.** Under `## Vendored skills`, add the link
   beneath the matching source heading. Group by source repo — one `###` heading
   per repo with a `Source:` line. If the repo has no heading yet, add one.
   ```markdown
   ### <source-name>

   Source: <github-folder-url>

   - [<name>](skills/<name>)
   ```
   Links are relative to `agents/README.md`, so the path is `skills/<name>`
   (no `agents/` prefix). Keep each heading's list alphabetical.
