---
feature: <Feature name>
status: draft            # draft | approved | in-progress | done
created: <YYYY-MM-DD>
planner: feature-planner@1.0.0
---

# Feature: <Feature name>

## 1. Summary

<Two to four sentences: what is being built, for whom, and the chosen approach.>

## 2. Requirements

- R1: <User-facing or technical requirement>
- R2: …

## 3. Existing Architecture

<Bullets on the relevant parts of the codebase today, citing confirmed files. End with the conventions this feature must follow and the test command.>

## 4. Proposed Approach

<How the feature fits into the existing architecture. If there was a real choice, name the alternative and why this one wins, in two or three lines.>

**Out of scope:** <comma-separated list>

## 5. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `path/to/file` | confirmed / proposed / TBD | <What changes> |

## 6. Implementation Tasks

- [ ] **T1 — <Title>** · `path/to/file` (confirmed), `path/to/new` (proposed) · depends on: none
  - Done when: <criterion>; <criterion>; <criterion>.
  - Tests: <test cases, in one or two lines>.
- [ ] **T2 — <Title>** · `path/to/other` (confirmed) · depends on: T1
  - Done when: …
  - Tests: …

## 7. Security, Data, and Compatibility

<!-- Optional: leave out if nothing applies. Auth checks, validation, sensitive data, migrations and rollback, backward compatibility. Don't repeat task criteria. -->

## 8. Risks, Assumptions, and Open Questions

<!-- Required. -->

- **Assumption:** …
- **Risk:** … — **Mitigation:** …
- **Question:** …
