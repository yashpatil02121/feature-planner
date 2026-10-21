---
feature: Mark todo as done and delete todo
status: draft
created: 2026-10-22
planner: feature-planner@0.3.0
---

# Feature: Mark todo as done and delete todo

## 1. Summary

Add two endpoints to the todo REST API: `PATCH /todos/:id` sets the `done` flag (true or false), and `DELETE /todos/:id` removes a todo. Both follow the existing Express router and in-memory store pattern. Unknown ids return 404 and invalid bodies return 400.

## 2. Requirements

- R1: `PATCH /todos/:id` with body `{ "done": boolean }` updates the todo and returns 200 with the updated todo.
- R2: `DELETE /todos/:id` removes the todo and returns 204 with no body.
- R3: Unknown or non-numeric ids return 404 `{ "error": "todo not found" }` for both methods.
- R4: A PATCH body without a boolean `done` returns 400 `{ "error": "done must be a boolean" }`.

## 3. Existing Architecture

- `src/server.js` (confirmed): creates the Express app, mounts `todosRouter` at `/todos`, and calls `app.listen(3000)` at import time, so it cannot be imported by tests.
- `src/routes/todos.js` (confirmed): `GET /` and `POST /` only. Errors use `res.status(...).json({ error })`.
- `src/store.js` (confirmed): module-level `todos` array and `nextId` counter. Exposes `list` and `add` only. Todos are `{ id, title, done }`.
- `test/store.test.js` (confirmed): one test that asserts the first `add` returns id 1, so test order matters.
- Tooling (confirmed in `package.json`): ESM, Express `^4.19.2`, `npm test` runs `node --test` with no test dependencies.

## 4. Proposed Approach

Add `update(id, changes)` and `remove(id)` to the store, add the two routes to the router, and extract the app setup into `src/app.js` so route tests can run on an ephemeral port without binding 3000.

Alternatives considered:

- `POST /todos/:id/done` for completion: rejected because it can't mark a todo as not done without a second endpoint.
- Soft delete (a `deleted` flag): rejected because nothing reads deleted todos and it adds filtering to `list`.

## 5. Scope

### In Scope

- PATCH `/todos/:id` accepting `done` only
- DELETE `/todos/:id` as a hard delete from the in-memory store
- 404 and 400 handling as above
- Store and route tests

### Out of Scope

- Editing `title` through PATCH
- Persistence, authentication, or authorization (none exist in the app today)
- Bulk operations, filtering by `done`, or a README (there is none to update)

## 6. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `src/store.js` | confirmed | Add `update(id, changes)` and `remove(id)` |
| `src/routes/todos.js` | confirmed | Add `PATCH /:id` and `DELETE /:id` handlers |
| `src/app.js` | proposed | Build and export the Express app (move `express()`, `json()`, and `/todos` mount out of `server.js`) |
| `src/server.js` | confirmed | Import `app` from `app.js` and keep `listen(3000)` |
| `test/store.test.js` | confirmed | Add tests for `update` and `remove` |
| `test/todos.routes.test.js` | proposed | HTTP tests for the new routes |

## 7. Implementation Tasks

### T1 — Store update and remove

- [ ] **Objective:** Give the store the two mutations the routes need.
- **Files:** `src/store.js` (confirmed), `test/store.test.js` (confirmed)
- **Depends on:** None
- **Acceptance criteria:**
  - `update(id, { done })` sets `done` on the matching todo and returns it, or returns `null` if no todo has that id.
  - `remove(id)` returns `true` and removes the todo, or returns `false` if missing.
  - Remaining todos keep their order, and ids are not reused after a delete.
- **Tests:**
  - Update existing todo to done and back to not done.
  - Update and remove on a missing id.
  - Remove keeps the other todos in order.
  - Add the new store tests after the existing id-1 test, or reset state first, so that test still passes.

### T2 — Extract app module

- [ ] **Objective:** Make the Express app importable without starting a listener, so route tests can use it.
- **Files:** `src/app.js` (proposed), `src/server.js` (confirmed)
- **Depends on:** None
- **Acceptance criteria:**
  - `src/app.js` exports the configured app and does not call `listen`.
  - `npm start` still serves the same routes on port 3000.
- **Tests:**
  - Covered by T4, which imports `app.js`. Run `npm test` to confirm nothing else changed.

### T3 — PATCH and DELETE handlers

- [ ] **Objective:** Expose done-toggling and deletion over HTTP.
- **Files:** `src/routes/todos.js` (confirmed)
- **Depends on:** T1
- **Acceptance criteria:**
  - Parse `req.params.id` with `Number` and check `Number.isInteger`. A non-integer id is treated as not found.
  - PATCH with a non-boolean `done` (including a missing body) returns 400 before the store is touched.
  - PATCH with a valid body returns 200 and the updated todo.
  - DELETE returns 204 with no body.
  - Unknown ids return 404 for both methods.
- **Tests:** Covered by T4.

### T4 — Route tests

- [ ] **Objective:** Verify the HTTP contract end to end inside the test runner.
- **Files:** `test/todos.routes.test.js` (proposed)
- **Depends on:** T2, T3
- **Acceptance criteria:**
  - Start the app with `listen(0)` and close it after the tests.
  - Cover each of R1 through R4, including the status code and response body.
- **Tests:**
  - PATCH `{ done: true }` then `{ done: false }` returns the updated todo.
  - PATCH `{ done: "yes" }` and PATCH with no body each return 400.
  - PATCH and DELETE on an unknown id and on `abc` return 404.
  - DELETE returns 204, and a later GET no longer lists the todo.

## 8. Testing Strategy

Run `npm test` (`node --test`). It uses the built-in runner, so no new dependencies are needed. Store tests (T1) use the functions directly. Route tests (T4) use the global `fetch` available in Node 18+, which is an assumption (see below). No manual testing steps are required beyond the route tests.

## 9. Security and Data Considerations

- No authentication exists, so any client can delete any todo. Flagged as a known gap, not addressed here.
- Input is validated at the boundary: the id must be an integer and `done` must be a boolean. Nothing is interpolated into strings.
- No migrations, since storage is in memory. Existing clients are unaffected because the change only adds routes.

## 10. Risks and Assumptions

- **Assumption:** Node 18 or later is available, so global `fetch` works in tests. The repo does not declare an engines field.
- **Assumption:** Deletes are hard deletes and ids are never reused.
- **Assumption:** A todo is marked done with `PATCH`, and the same endpoint can set it back to not done.
- **Risk:** The store is a shared module singleton, so test order can break assertions. **Mitigation:** Put store tests in a fixed order and keep the id-1 assertion first.
- **Risk:** `store.list()` returns the internal array, so callers can mutate it. Existing behavior, not changed here. **Mitigation:** Leave as is; note for later.

## 11. Open Questions

- Should a DELETE on an already-deleted id return 404 (assumed) or 204?
- Is a non-numeric id better as 400 than 404? The plan uses 404 to keep the response uniform.

## 12. Definition of Done

- [ ] All tasks complete and their acceptance criteria met
- [ ] `npm test` passes
- [ ] `npm start` serves the existing and new routes on port 3000
- [ ] Manual check with curl: PATCH, DELETE, and 404 cases behave as specified
