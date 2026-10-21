# Plan quality checklist

Run through this before saving. Fix what you can, and record the rest in the plan's risks and open questions section.

## Grounding

- [ ] Every file marked **confirmed** was read in this run.
- [ ] No invented paths. Proposed paths follow the project's existing layout.
- [ ] The stack named in the plan matches the dependency manifests.
- [ ] Assumptions are written down, not silently baked into tasks.

## Coverage

- [ ] Every requirement maps to at least one task and one acceptance criterion.
- [ ] Error cases and edge cases are covered, not just the happy path.
- [ ] If `generateTests` is true, every task that changes behavior has tests, and the plan names the project's real test command (in Context or Existing Architecture).

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

- [ ] The right template was used: compact for small changes (about 80 lines or fewer), full otherwise (about 150 lines or fewer).
- [ ] No detail is repeated across sections. Requirements are not restated as criteria, and files are not listed twice.
- [ ] Each task is a header line plus "Done when" and "Tests". No extra sub-bullets.
- [ ] No speculative work beyond the request. Nice-to-haves go under "Out of Scope".

## Safety

- [ ] The plan contains no secret values (keys, tokens, passwords, connection strings).
- [ ] The plan does not include code changes that were applied during planning. Nothing was applied.
