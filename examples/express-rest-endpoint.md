---
feature: Mark a todo as done and delete a todo
status: draft
created: 2026-10-22
planner: feature-planner@0.3.0
---

# Feature: Mark a todo as done and delete a todo

## Summary

Add two endpoints to the todo API: `PATCH /todos/:id` with a `done` boolean to mark a todo done (or back to not done), and `DELETE /todos/:id` to remove it. Both follow the existing in-memory store and router pattern, with store methods that the route calls. A single PATCH endpoint was chosen over a separate `POST /todos/:id/done`, because it covers both directions with one route and the store already holds a boolean `done` field. Nothing in the project needs a new dependency.

## Context

- `src/store.js` (confirmed): in-memory `todos` array and `nextId` counter; `add` is the only mutator, and `list` returns the internal array.
- `src/routes/todos.js` (confirmed): `Router` with `GET /` and `POST /`; validation failures return `res.status(400).json({ error: "..." })`.
- `src/server.js` (confirmed): mounts the router at `/todos` and calls `app.listen(3000)` on import, so tests cannot import it.
- `test/store.test.js` (confirmed): `node:test` and `node:assert`, with one test.
- Conventions: ESM with `.js` import suffixes, 2-space indent, error bodies shaped `{ error: string }`.
- Tests run with `npm test` (`node --test`).

## Changes

| File | Status | Change |
| ---- | ------ | ------ |
| `src/store.js` | confirmed | Add `update(id, patch)` and `remove(id)`, both returning `null` for an unknown id. |
| `src/routes/todos.js` | confirmed | Add `PATCH /:id` and `DELETE /:id`. |
| `test/store.test.js` | confirmed | Add store tests for update and remove. |
| `test/todos.route.test.js` | proposed | Route tests against a fresh Express app that mounts `todosRouter`. |

## Tasks

- [ ] **T1 — Store update and remove** · `src/store.js` (confirmed), `test/store.test.js` (confirmed) · depends on: none
  - Done when: `update(id, { done })` sets `done` and returns the same todo object, or `null` if the id is unknown; `remove(id)` deletes the todo and returns it, or `null` if the id is unknown; ids are never reused after a removal.
  - Tests: update sets `done` to true and back to false; update and remove of an unknown id return `null`; a removed todo no longer appears in `list()`; an add after a remove gets a new id.

- [ ] **T2 — PATCH and DELETE routes** · `src/routes/todos.js` (confirmed), `test/todos.route.test.js` (proposed) · depends on: T1
  - Done when: `PATCH /todos/:id` with `{ "done": boolean }` returns 200 and the updated todo; a missing or non-boolean `done` returns 400 `{ error: "done must be a boolean" }`; an unknown or non-numeric id returns 404 `{ error: "todo not found" }`; `DELETE /todos/:id` returns 204 with no body, or 404 for an unknown id.
  - Tests: PATCH true and false; PATCH with a string `done` returns 400; PATCH and DELETE on an unknown id return 404; PATCH and DELETE on `"abc"` return 404; DELETE then GET no longer lists the todo; a second DELETE of the same id returns 404. Use an ephemeral port (`listen(0)`) and `fetch`.

## Risks and open questions

- **Assumption:** `PATCH` accepts `done: false` as well, so a todo can be reopened. If only one-way completion is wanted, reject `false` with 400 instead.
- **Assumption:** the API has no auth today, so these endpoints are unrestricted, the same as `POST`.
- **Assumption:** the route test mounts the router on its own Express app because `server.js` listens on port 3000 at import. Exporting the app from `server.js` would be cleaner but touches more files.
- **Risk:** `list()` returns the internal array, so a caller that mutates it bypasses `update` and `remove`. No caller does this today. Mitigation: return copies in a later change if needed.
- **Question:** should deleting an already-deleted id return 404 (as planned) or 204 for idempotency?
