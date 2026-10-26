---
feature: <Feature name>
status: draft            # draft | approved | in-progress | done
created: <YYYY-MM-DD>
planner: feature-planner@1.0.0
---

# Feature: <Feature name>

## Summary

<Two to four sentences: what changes, the approach, and why it fits the existing code. Mention any real alternative in one clause.>

## Context

- `path/to/file` (confirmed): <the one fact about it that matters for this feature>
- Conventions: <naming, error shape, test style to follow>
- Tests run with `<project test command>`.

## Changes

| File | Status | Change |
| ---- | ------ | ------ |
| `path/to/file` | confirmed | <What changes> |
| `path/to/new_file` | proposed | <What it contains> |

## Tasks

- [ ] **T1 — <Title>** · `path/to/file` · depends on: none
  - Done when: <criterion>; <criterion>; <criterion>.
  - Tests: <test cases, in one line>.
- [ ] **T2 — <Title>** · `path/to/other` · depends on: T1
  - Done when: …
  - Tests: …

## Risks and open questions

<!-- Required. Assumptions you made, risks with a mitigation, and questions for the reviewer. At most about five bullets. -->

- **Assumption:** …
- **Question:** …
