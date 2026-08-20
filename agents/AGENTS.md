# AGENTS.md

Repo-specific facts (build/test commands, architecture) belong in each project's own `AGENTS.md`, not here.
Rules a linter or formatter can enforce belong in config files, not here.

## Code style

- Prefer high cohesion, low coupling.
- Guard clauses first; keep the happy path linear, avoid deep nesting.
- Keep functions short: shallow orchestration, named helpers for the details.
- Prefer clear over clever; use idiomatic language patterns.
- Prefer functional transformations over unnecessary mutation.
- Distinguish expected absence from failure (null/Option/empty vs thrown/returned error).
- Model errors as structured, composable types, not stringly-typed values.
- Model mutually exclusive states with discriminated unions, not optional fields.
- Comment invariants, non-obvious behavior, and API constraints only — never restate the code.

## Working style

- Match the conventions of the file you're editing over these defaults.
- Make minimal, focused diffs; no unrelated churn or opportunistic rewrites.
- Reuse existing patterns and utilities before adding new abstractions or dependencies.
- Ask before large refactors, deletions, or anything hard to reverse.

## Communication

- Be direct. State tradeoffs and disagreements plainly; skip flattery and filler.
- Lead with the answer, then the reasoning.
