# Vitest mechanics

Version markers: unmarked API is Vitest 3+; `4.0` and `4.1` mark later additions.

## Config baseline

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Kill cross-test bleed once, here, instead of afterEach blocks in every file.
    restoreMocks: true,
    unstubEnvs: true,
    unstubGlobals: true,

    // A test that asserts nothing is a false green.
    expect: { requireAssertions: true },

    // Surfaces order dependence between files and tests.
    sequence: { shuffle: true },

    // 4.1: dangling timers and handles fail the run instead of flaking a later file.
    detectAsyncLeaks: true,

    setupFiles: ['./test/setup.ts'],

    coverage: {
      provider: 'v8',
      // 4.0 removed coverage.all: files are only reported if listed here.
      include: ['src/**/*.{ts,tsx}'],
      thresholds: { lines: 80, branches: 80 },
    },
  },
});
```

`restoreMocks` restores spies created with `vi.spyOn`. In 4.0 it no longer un-mocks modules registered with
`vi.mock`; those are reset per file. `requireAssertions` counts `expect` calls only, so tests using Node's
`assert` need `expect.hasAssertions()` removed or a different guard.

Multiple environments in one repo use `projects` (4.0 renamed `workspace`):

```ts
export default defineConfig({
  test: {
    projects: [
      { test: { name: 'node', environment: 'node', include: ['src/**/*.test.ts'] } },
      { test: { name: 'dom', environment: 'jsdom', include: ['src/**/*.test.tsx'] } },
    ],
  },
});
```

## Fixtures

Fixtures replace `beforeEach` plus module-level `let`. Setup is typed, lazily created only for tests that
name it, and torn down through `onCleanup`.

```ts
// test/fixtures.ts
import { test as base } from 'vitest';

export const test = base
  .extend('config', { host: 'localhost', port: 3000 })
  .extend('db', { scope: 'file' }, async ({}, { onCleanup }) => {
    const db = await createDatabase();
    onCleanup(() => db.close());
    return db;
  })
  .extend('user', async ({ db }) => db.insertUser(makeUser()));
```

The string-plus-callback builder is 4.1; it infers fixture types from the return value. On Vitest 3 use the
object form, which needs an explicit type parameter and a `use` callback:

```ts
const test = base.extend<{ db: Database }>({
  db: async ({}, use) => {
    const db = await createDatabase();
    await use(db);
    await db.close();
  },
});
```

Scopes: `test` (default, fresh per test), `file` (once per file), `worker` (once per worker process). A
fixture may only depend on its own scope or wider. `{ auto: true }` runs the fixture for every test even
when unnamed, which is the right home for a metrics collector or a leak assertion.

Override inside a `describe` with `test.override('config', { port: 8080 })` (4.1) or `test.scoped` on 3.x.
Hooks called on the extended `test` receive the fixtures: `test.beforeEach(({ db }) => ...)`. `aroundEach`
and `aroundAll` (4.1) wrap a test in surrounding context that a before/after pair cannot express: a
transaction, a tracing span, an `AsyncLocalStorage` run.

## Mocking

```ts
// Partial: real implementation runs, calls recorded.
vi.mock('./calculator.ts', { spy: true });

// Factory needs vi.hoisted, because vi.mock is hoisted above the imports.
const { sendEmail } = vi.hoisted(() => ({ sendEmail: vi.fn() }));
vi.mock('./mailer.ts', () => ({ sendEmail }));

// Keep the rest of the module real.
vi.mock('./config.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./config.ts')>()),
  isProduction: true,
}));

// Types for an already-mocked import.
vi.mocked(calculator.add).mockReturnValue(10);

// Deep-mock an object without touching the module graph.
const client = vi.mockObject(realClient);

// 4.1
fetchUser.mockThrowOnce(new NetworkError('timeout'));
```

`vi.mock` only intercepts imports across module boundaries. A function calling its own sibling export
directly is not intercepted; that is a design signal, not a Vitest limitation.

### HTTP

```ts
// test/setup.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

`onUnhandledRequest: 'error'` turns an unexpected request into a failure, which is how you catch a test
hitting the wrong URL. `resetHandlers` stops a per-test `server.use()` override from leaking forward.

## Time and async

```ts
beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

it('retries three times before giving up', async () => {
  const result = client.fetchWithRetry('/users');

  await vi.advanceTimersByTimeAsync(3_000);

  await expect(result).rejects.toThrow(RetryExhaustedError);
});
```

`advanceTimersByTimeAsync` flushes promise chains scheduled by the timers; the sync `advanceTimersByTime`
does not. `vi.setSystemTime(new Date('2026-01-01T00:00:00Z'))` moves the clock without firing timers.

Waiting on a condition, in preference order:

```ts
await expect.poll(() => store.getState().status).toBe('ready');   // retries the assertion
await vi.waitFor(() => server.isReady, { timeout: 500 });          // retries until no throw
const el = await vi.waitUntil(() => document.querySelector('.el')); // retries until truthy
```

Under fake timers, `vi.waitFor` advances them for you.

## Assertions worth knowing

```ts
expect.soft(res.status).toBe(200);            // collect failures, keep going
expect.unreachable('parse should have thrown');
expect(value).toSatisfy((n) => n % 2 === 1);
expect(user).toEqual({ email: expect.schemaMatching(z.string().email()) }); // 4.0, Standard Schema v1

const assertPair = vi.defineHelper((a, b) => expect(a).toEqual(b)); // 4.1: stack points at the call site
```

## Tags (4.1)

```ts
// vitest.config.ts
test: {
  tags: [
    { name: 'unit' },
    { name: 'db', timeout: 60_000 },
    { name: 'flaky', description: 'Quarantined; excluded from the default run.' },
  ],
}
```

```ts
test('writes the audit row', { tags: ['db'] }, async ({ db }) => { /* ... */ });
describe('checkout', { tags: ['e2e'] }, () => { /* inherited */ });
```

```bash
vitest --tags-filter="!flaky"
vitest --tags-filter="(unit || db) && !flaky"
```

A file-wide tag goes in a `@module-tag` JSDoc comment at the top of the file.

## Property-based testing

```ts
import fc from 'fast-check';

it('round-trips through serialize and parse', () => {
  fc.assert(
    fc.property(fc.record({ id: fc.uuid(), tags: fc.array(fc.string()) }), (value) => {
      expect(parse(serialize(value))).toEqual(value);
    }),
  );
});
```

Reach for this when the input space is wide and an invariant holds across all of it: round-trip,
idempotence, commutativity, ordering, or agreement with a slow reference implementation. Shrinking is what
makes it practical, because a failure reports the smallest input that reproduces it. Keep example-based tests for
the specific cases you care about; a property test is a complement, not a replacement.

## Migration deltas

Coming from Jest, or from Vitest 3:

| Change                                    | Now                                                              |
|-------------------------------------------|------------------------------------------------------------------|
| `jest.fn` / `jest.mock` / `jest.spyOn`    | `vi.fn` / `vi.mock` / `vi.spyOn`                                 |
| Auto-injected globals                     | Import from `vitest`, or set `globals: true`                     |
| `workspace`                               | `projects` (4.0)                                                 |
| `maxThreads` / `maxForks`                 | `maxWorkers` (4.0)                                               |
| `singleThread` / `singleFork`             | `maxWorkers: 1, isolate: false` (4.0)                            |
| `poolOptions.*` nesting                   | Flattened to top-level options (4.0)                             |
| `coverage.all`, `coverage.extensions`     | Removed; list `coverage.include` explicitly (4.0)                |
| `environmentMatchGlobs`, `poolMatchGlobs` | Removed; use `projects` (4.0)                                    |
| `basic` reporter                          | `default` with `summary: false` (4.0)                            |
| `@vitest/browser` + provider string       | `@vitest/browser-playwright` et al., import from `vitest/browser` (4.0) |
| `vi.restoreAllMocks` un-mocking modules   | Restores manual spies only (4.0)                                 |
| `mock.invocationCallOrder` starting at 0  | Starts at 1 (4.0)                                                |

Node 20+ and Vite 6+ are required by Vitest 4.
