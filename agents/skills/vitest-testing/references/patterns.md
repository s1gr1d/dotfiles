# Patterns

Good and bad pairs for the rules in `SKILL.md`.

## Arrange / Act / Assert

```ts
it('skips errors already captured upstream', () => {
  const error = new Error('boom');
  Object.defineProperty(error, CAPTURED_FLAG, { value: true });

  handleResponse(makeContext({ status: 500, error }));

  expect(captureException).not.toHaveBeenCalled();
});
```

Three blocks, blank lines between them, nothing else.

## Fail loudly

```ts
// Bad: a non-transaction envelope satisfies the expectation without asserting anything.
.expect((envelope) => {
  if (itemType(envelope) !== 'transaction') return;
  expect(envelope.items[0].transaction).toBe('GET /users/:id');
});

// Good: the precondition is an assertion, so a wrong envelope fails the test.
.expect((envelope) => {
  expect(itemType(envelope)).toBe('transaction');
  expect(envelope.items[0].transaction).toBe('GET /users/:id');
});
```

The same applies to any predicate or callback: if a condition must hold for the assertions to mean
anything, assert it.

## Behavior, not wiring

```ts
// Bad: asserts that the code does not crash.
it('handles the request', async () => {
  await expect(handler(request)).resolves.not.toThrow();
});

// Good: asserts the observable outcome.
it('names the transaction after the matched route', async () => {
  await handler(makeRequest({ method: 'GET', route: '/users/:id' }));

  expect(setTransactionName).toHaveBeenCalledWith('GET /users/:id');
});
```

## Precise assertions

```ts
// Bad: passes when the shape gains or loses a field.
expect(startSpan).toHaveBeenCalledWith(
  expect.objectContaining({ name: 'middleware', op: 'middleware.hono' }),
);

// Good: every argument spelled out, so a shape change fails the test.
expect(startSpan).toHaveBeenCalledWith({
  name: 'middleware',
  op: 'middleware.hono',
  onlyIfParent: true,
  parentSpan: rootSpan,
  attributes: { 'sentry.op': 'middleware.hono', 'sentry.origin': 'auto.middleware.hono' },
});
```

When the object is framework-owned and carries fields you do not control, prefer individual checks over
`objectContaining`:

```ts
expect(event.transaction).toBe('GET /users/:id');
expect(event.contexts?.trace?.op).toBe('http.server');
```

## Count with content

```ts
// Bad: still passes when an unexpected extra span appears.
expect(spanNames).toContain('authMiddleware');

// Good.
expect(spanNames).toHaveLength(1);
expect(spanNames).toContain('authMiddleware');
```

## Named constants

```ts
// Bad: silently passes with the wrong expectation if the constant changes.
expect(span.status.code).toBe(1);

// Good.
expect(span.status.code).toBe(SPAN_STATUS_OK);
```

## Errors

```ts
// Bad: any throw passes, including a TypeError from a typo in the test.
await expect(parseConfig('{')).rejects.toThrow();

// Good: the type and the message are both part of the contract.
await expect(parseConfig('{')).rejects.toThrow(ConfigParseError);
await expect(parseConfig('{')).rejects.toThrow(/unexpected end of input/);
```

## Fixtures over shared state

```ts
// Bad: mutable module state, order-dependent, and every test pays for the setup.
let db: Database;
let user: User;
beforeEach(async () => {
  db = await createDatabase();
  user = await db.insertUser({ name: 'Test' });
});
afterEach(async () => db.close());

// Good: typed, per-test, torn down with the fixture, created only for tests that name it.
const test = base
  .extend('db', { scope: 'file' }, async ({}, { onCleanup }) => {
    const db = await createDatabase();
    onCleanup(() => db.close());
    return db;
  })
  .extend('user', async ({ db }) => db.insertUser(makeUser()));

test('soft-deletes the user', async ({ db, user }) => { /* ... */ });
```

## Builders

```ts
// test/factories.ts: one complete, realistic default per entity.
export const makeUser = (overrides: Partial<User> = {}): User => ({
  id: 'usr_01H8XGJWBWBAQ4V2JQKZ5VJZ9K',
  email: 'ada@example.com',
  role: 'member',
  createdAt: new Date('2026-01-01T00:00:00Z'),
  ...overrides,
});

// The test reads as its own delta from the default.
it('denies deletion to non-admins', () => {
  expect(canDelete(makeUser({ role: 'member' }))).toBe(false);
});
```

## Fake over mock

```ts
// Bad: asserts the implementation's call sequence; breaks on any refactor.
expect(store.get).toHaveBeenNthCalledWith(1, 'user:42');
expect(store.set).toHaveBeenNthCalledWith(2, 'user:42', user);

// Good: an in-memory implementation of the same interface, asserted through observable state.
const store = new InMemoryKeyValueStore();
const cache = new UserCache(store);

await cache.load('42');
await cache.load('42');

expect(await store.get('user:42')).toEqual(user);
expect(fetchUser).toHaveBeenCalledTimes(1);
```

## No sleeping

```ts
// Bad: slow, and flaky on a loaded CI box.
await new Promise((r) => setTimeout(r, 100));
expect(store.getState().status).toBe('ready');

// Good: retries against a deadline.
await expect.poll(() => store.getState().status).toBe('ready');
```

## Boundaries

```ts
it.for([
  [-1, false],
  [0, false],
  [1, true],
  [2, true],
  [99, true],
  [100, true],
  [101, false],
  [Number.NaN, false],
  [Number.POSITIVE_INFINITY, false],
])('isValidQuantity(%s) is %s', ([input, expected]) => {
  expect(isValidQuantity(input)).toBe(expected);
});
```

One table when the rows differ only in data. The moment a row needs a different assertion, it is its own
test with its own name.

## Names

| Verdict | Name                                                                                      |
|---------|-------------------------------------------------------------------------------------------|
| Good    | `'captures the error when the context carries one'`                                       |
| Good    | `'does not re-capture an error the middleware already reported'`                          |
| Good    | `'returns an empty array when nothing matches'`                                           |
| Bad     | `'should correctly return the formatted price string when given a valid positive number'` |
| Bad     | `'test error handling'`                                                                   |
| Bad     | `'works correctly'`                                                                       |
