## Code Style

- Prefer high cohesion, low coupling.
- Use guard clauses first; keep the happy path linear and avoid deeply nested control flow.
- Keep functions short: shallow orchestration, named helpers for readability.
- Prefer clear over clever; use idiomatic language patterns.
- Avoid unnecessary mutability; prefer functional transformations or interim variables.
- Distinguish expected absence from failure (null/Option/empty vs thrown/returned errors).
- Prefer structured, composable error types over stringly-typed errors.
- Separate logically distinct blocks with blank lines; always add a blank line before and after control flow.
- Never comment what the code already says; document non-obvious behavior, invariants, and API constraints only.

### JS/TS

- Prefer explicit return types on public/exported functions.
- Avoid `any`; use `unknown` and narrow explicitly.
- Prefer `type` over `interface` unless declaration merging is needed.
- Use discriminated unions over optional fields to model mutually exclusive states.

- Prefer `const` by default; use `let` only when reassignment is genuinely needed.
- Prefer `structuredClone` / spread for immutable updates over direct mutation.
- Avoid `null` where `undefined` is the language default for absence; pick one and be consistent.
- Don't use `!` non-null assertions unless you can't avoid them — narrow instead.
- Prefer named exports over default exports for better refactor-ability and explicit imports.