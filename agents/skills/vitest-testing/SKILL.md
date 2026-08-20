---
name: vitest-testing
description: Test engineering rules for any JavaScript or TypeScript repo on Vitest.
disable-model-invocation: true
---

# Vitest testing

Rules for writing and reviewing tests in any JS/TS repo on Vitest. Baseline is Vitest 3; API added in 4.0 or
4.1 is marked. Language-agnostic rules sit in the tables; Vitest mechanics and full examples sit in
`references/`.

## The loop

1. **Name the bug.** Before writing a test, say which defect it catches. No concrete answer, no test.
2. **Write it.**
3. **Prove it goes red.** After each group of tests, mutate the code under test in two or three places
   (flip a boundary, delete a branch, return the wrong shape) and confirm the tests you expected fail, for
   the reason you named. Revert. A test that stays green on a broken implementation is dead weight: it costs
   runtime and buys a false green. This is hand-run mutation testing; automate it with Stryker where the
   suite is worth it.
4. **Sweep the diff** against every rule below.

Done when every new test has been proven red and every rule has been applied or explicitly waived.

## Selection

A large suite of shallow happy-path tests passes on every change, including the change that ships the bug.
Fewer, sharper tests catch more.

| Rule               | Summary                                                                                                                                                        |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Bug-first          | Every test names a defect it catches. Edge cases, error paths, seams, and past regressions first.                                                              |
| Test the seam      | Bugs cluster where two modules or systems meet: middleware calling `next()`, a retry wrapper around a client, a reducer feeding a selector. Cover the handoff. |
| Public boundary    | Test what the module exports. If a refactor that preserves behavior breaks the test, the test asserts wiring, not behavior.                                    |
| Skip the trivial   | No tests for getters, pure delegation to a well-tested library, or constraints the type checker already enforces.                                              |
| Coverage diagnoses | Coverage finds untested branches; it does not measure suite strength. A line covered by a test that cannot go red is uncovered. Never chase the percentage.    |
| Regression link    | A test for a fixed bug carries the issue reference: `annotate('#1234', 'issues')`, or a one-line comment stating what broke.                                   |

## Structure and isolation

| Rule                   | Summary                                                                                                                                                                  |
|------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Arrange / Act / Assert | Three blocks separated by blank lines. The whitespace does the labeling; no `// Arrange` comments.                                                                       |
| One reason to fail     | One behavioral claim per test. Several `expect`s on facets of the same outcome are fine; two unrelated behaviors are two tests.                                          |
| Straight line          | No `if`, no loops, no `try`/`catch` in a test body. Branching means the test does not know what it asserts.                                                              |
| Fail loudly            | An early `return` inside a callback or predicate satisfies the expectation while asserting nothing. Assert the precondition instead of skipping past it.                 |
| Verb-first names       | `'captures the error when the context carries one'`. Drop "should". Names read as correct English and state the observable outcome.                                      |
| Fixtures over hooks    | `test.extend` fixtures with `onCleanup` instead of `beforeEach` plus mutable module-level `let`. Setup is typed, per-test, and cannot bleed. See `references/vitest.md`. |
| Builders over literals | One `makeUser(overrides)` factory returning a complete realistic object; each test overrides only the field it exercises, so the test reads as its own delta.            |
| Colocate               | Test file beside the source file, or a mirrored `__tests__`. Match what the repo already does.                                                                           |

## Assertions

Loose matching is where real bugs slip through: `toMatchObject`, `objectContaining`, and `arrayContaining`
silently ignore fields that matter.

| Rule                                  | Summary                                                                                                                                                                                         |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `toEqual` by default                  | Spell out the whole expected value. Same for `toHaveBeenCalledWith`: write every argument.                                                                                                      |
| `toStrictEqual`                       | Use when class identity, `undefined` keys, or array sparseness are part of the contract.                                                                                                        |
| Loose only when owned elsewhere       | `toMatchObject`/`objectContaining` are for objects a framework or third party builds, carrying fields you do not control. Then prefer individual `.toBe()` checks on the fields you care about. |
| `toContain` pairs with `toHaveLength` | Without the count, the assertion passes when extra unexpected items appear.                                                                                                                     |
| Named constants                       | Assert against the same exported constant the code uses, never its literal value.                                                                                                               |
| Errors are typed                      | `await expect(fn()).rejects.toThrow(ValidationError)` plus a message check. "It threw something" is not an assertion.                                                                           |
| Assertion count                       | Set `expect.requireAssertions: true` in config so a test with no `expect` fails. For callback-driven code add `expect.assertions(n)`.                                                           |
| Snapshots stay small                  | `toMatchInlineSnapshot` on a narrow, stable, serializable value. Never snapshot a whole DOM tree or an API response: nobody reviews the diff, so it locks in bugs.                              |
| `expect.soft`                         | Collect several independent failures in one run instead of stopping at the first. Not a license to break one-reason-to-fail.                                                                    |

## Test doubles

Every double is a claim that the real thing behaves this way, and the claim goes stale silently. Climb the
ladder only as far as you must: **real > fake > stub > spy > mock**.

| Rule                  | Summary                                                                                                                                                 |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| Mock at the boundary  | Double only what you do not own or cannot run: network, clock, filesystem, randomness, a paid third-party SDK. Never double your own business logic.    |
| Fake beats mock       | An in-memory implementation of the interface stays honest under refactor; a mock asserting call order encodes today's implementation.                   |
| HTTP at the wire      | Intercept with MSW handlers and `onUnhandledRequest: 'error'`, so an unexpected request fails the test. Do not replace `globalThis.fetch`.              |
| Partial over total    | `vi.mock(path, { spy: true })` keeps the real implementation and records calls. Full factory mocks only where the real module cannot run.               |
| Config kills bleed    | `restoreMocks`, `unstubEnvs`, `unstubGlobals` in config, not `afterEach` blocks in every file.                                                          |
| Mock count is a smell | A test whose arrange block is mostly mock setup is testing the mocks. Extract a fake, or move the test up to the seam where the real collaborators run. |

## Async and determinism

| Rule                  | Summary                                                                                                                                                     |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Never sleep           | `await new Promise(r => setTimeout(r, 100))` is a slow flake. Use `expect.poll`, `vi.waitFor`, or a `findBy*` query, all of which retry against a deadline. |
| Own the clock         | `vi.useFakeTimers()` and `await vi.advanceTimersByTimeAsync(ms)`; `vi.setSystemTime` for date logic. Restore with `vi.useRealTimers()`.                     |
| Inject nondeterminism | Time, randomness, and id generation are parameters, not ambient calls. Injection beats stubbing where you control the source.                               |
| Abort on timeout      | Pass the test context `signal` to `fetch` and other cancellable work so a timing-out test tears its work down.                                              |
| Leaks fail the run    | `detectAsyncLeaks` (4.1) surfaces dangling timers and handles that would otherwise flake a later file.                                                      |
| Await every promise   | An un-awaited assertion inside a floating promise reports as a pass. Lint for it.                                                                           |

## Inputs

| Rule                  | Summary                                                                                                                                                                                    |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Realistic data        | `'https://api.example.com/users/42?include=profile'` exercises parsing; `'http://test'` exercises nothing.                                                                                 |
| Boundary values       | Valid range 1 to 100 means testing -1, 0, 1, 2, 99, 100, 101, `NaN`, `Infinity`. Off-by-one and inclusive/exclusive confusion live here.                                                   |
| Falsy but valid       | `0`, `''`, `false`, `NaN`, empty array, empty object. These break loose truthiness checks.                                                                                                 |
| Unhappy path equally  | Network failure, malformed payload, missing required field, timeout, called twice, called after teardown. Each gets its own named test.                                                    |
| Table-driven          | `test.for` (context without spreading) or `test.each` when rows differ only in data. Different assertions per row means separate tests.                                                    |
| Properties over cases | Use fast-check where the input space is wide and one invariant holds across it: round-trip, idempotence, ordering, agreement with an oracle. It complements examples, never replaces them. |

## Suite health

| Rule                  | Summary                                                                                                                                     |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| Shuffle               | `sequence.shuffle` exposes order dependence. It is a one-time cleanup cost and a permanent guard.                                           |
| No `retry` on flake   | Retries convert a real race into an intermittent green. Fix the cause, or tag the test and quarantine it out of the default run (4.1 tags). |
| No parked tests       | `.skip` and `.todo` are tracked work items with an issue link, not permanent residents. `.only` fails CI by default; keep it that way.      |
| Tag the slow tiers    | Tags with per-tag timeouts split unit, db, and browser tiers in one config instead of separate scripts (4.1).                               |
| Agent-friendly output | Run with `--reporter=agent` when an agent reads the output: failures only, no passing noise.                                                |

## UI and browser tests

Prefer the real browser (Browser Mode, stable in 4.0) over jsdom when the code touches layout, focus, or
real event dispatch. Query by role first, then label, then text; `getByTestId` is the last resort. Drive
interactions with `userEvent` from a `userEvent.setup()` instance, not `fireEvent`. Await `findBy*` rather
than wrapping in `act`. Query through `screen`, not the render `container`. Visual regressions go through
`toMatchScreenshot` (4.0).

## References

- `references/vitest.md`: config baseline, fixtures, mocking, timers, and the Vitest 4 API and migration deltas.
- `references/patterns.md`: good and bad code pairs for the rules above.
