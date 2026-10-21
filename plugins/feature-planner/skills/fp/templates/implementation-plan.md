---
feature: <Feature name>
status: draft            # draft | approved | in-progress | done
created: <YYYY-MM-DD>
planner: feature-planner@0.1.0
---

# Feature: <Feature name>

## 1. Summary

<Two to four sentences: what is being built, for whom, and the chosen approach.>

## 2. Requirements

- R1: <User-facing or technical requirement>
- R2: …

## 3. Existing Architecture

<What the relevant parts of the codebase look like today, citing confirmed files. Note the conventions this feature must follow.>

## 4. Proposed Approach

<How the feature fits into the existing architecture. If there was a real choice, list the alternatives considered and why this one was chosen.>

## 5. Scope

### In Scope

- …

### Out of Scope

- …

## 6. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `path/to/file` | confirmed / proposed / TBD | <What changes> |

## 7. Implementation Tasks

### T1 — <Task title>

- [ ] **Objective:** <What this task achieves>
- **Files:** `path/to/file` (confirmed), …
- **Depends on:** None
- **Acceptance criteria:**
  - …
- **Tests:**
  - …

### T2 — <Task title>

- [ ] **Objective:** …
- **Files:** …
- **Depends on:** T1
- **Acceptance criteria:**
  - …
- **Tests:**
  - …

## 8. Testing Strategy

<Test runner and commands used by this project, the unit, integration, and end-to-end coverage this feature needs, and important edge cases.>

## 9. Security and Data Considerations

<Authentication and authorization, input validation, sensitive data, migrations and rollback, backward compatibility. Write "None" if not applicable.>

## 10. Risks and Assumptions

- **Assumption:** …
- **Risk:** … — **Mitigation:** …

## 11. Open Questions

- …

## 12. Definition of Done

- [ ] All tasks complete and their acceptance criteria met
- [ ] Tests pass using the project's test command
- [ ] Lint and type checks pass
- [ ] <Feature-specific criteria>
