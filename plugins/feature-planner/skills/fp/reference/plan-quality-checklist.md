# Plan quality checklist

Run through this before saving. Fix what you can; record the rest under "Open Questions" or "Risks and Assumptions".

## Grounding

- [ ] Every file marked **confirmed** was read in this run.
- [ ] No invented paths. Proposed paths follow the project's existing layout.
- [ ] The stack named in the plan matches the dependency manifests.
- [ ] Assumptions are written down, not silently baked into tasks.

## Coverage

- [ ] Every requirement maps to at least one task and one acceptance criterion.
- [ ] Error cases and edge cases are covered, not just the happy path.
- [ ] If `generateTests` is true, every task that changes behavior has tests, and the testing strategy names the project's real test runner.

## Ordering

- [ ] Every task's dependencies come before it.
- [ ] Schema and migration tasks come before code that relies on them.
- [ ] No circular dependencies.

## Task quality

- [ ] Each task has a clear objective and verifiable acceptance criteria.
- [ ] Each task is small enough to implement and verify in one sitting.
- [ ] Tasks are understandable without the original conversation.

## Risk areas (when relevant)

- [ ] **Security:** authentication and authorization checks, input validation, secret handling, injection and XSS, rate limiting.
- [ ] **Data:** migrations, backfills, rollback steps, backward compatibility with existing data and clients.
- [ ] **Compatibility:** public APIs, config formats, feature flags, deprecations.
- [ ] **Non-functional:** performance, accessibility, observability (logs, metrics), internationalization.

## Proportionality

- [ ] The plan's length matches the feature. A change touching a few files fits in about 80 lines.
- [ ] No detail is repeated across sections. For example, acceptance criteria are not restated in the testing strategy.
- [ ] No speculative work beyond the request. Nice-to-haves go under "Out of Scope".

## Safety

- [ ] The plan contains no secret values (keys, tokens, passwords, connection strings).
- [ ] The plan does not include code changes that were applied during planning. Nothing was applied.
