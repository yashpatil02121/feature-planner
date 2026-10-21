---
feature: Note tags and tag filtering
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@0.3.0
---

# Feature: Note tags and tag filtering

## 1. Summary

Users can attach tags to their notes when creating them and later replace a note's tags, then list their notes filtered by one tag. Tags are per-user, so one owner's tag names are never visible to another. Approach: normalized `tags` and `note_tags` tables added by one Alembic migration, a `tags: list[str]` field on the note schemas, and a `tag` query parameter on `GET /notes`.

## 2. Requirements

- R1: `POST /notes` accepts optional `tags` and returns them.
- R2: `PUT /notes/{note_id}/tags` replaces a note's tag set (owner only).
- R3: `GET /notes?tag=<name>` returns only the caller's notes with that tag, newest first.
- R4: Tag input is normalized and validated; invalid input returns 422.
- R5: Tags are owner-scoped. Acting on another user's note returns 404.
- R6: Existing clients keep working. Existing notes have no tags.

## 3. Existing Architecture

- `app/models.py` (confirmed): SQLAlchemy 2.0 `Mapped[...]` models. `User` and `Note` (`owner_id` FK, `User.notes` relationship).
- `app/schemas.py` (confirmed): `NoteCreate(title, body)` and `NoteOut` (`from_attributes=True`).
- `app/routers/notes.py` (confirmed): `GET /notes` and `POST /notes` only. `create_note` does `Note(owner_id=user.id, **payload.model_dump())`, so a new `tags` field must be removed first or the constructor fails.
- `app/auth.py` (confirmed): placeholder auth, trusts the `X-User-Id` header.
- `app/db.py` (confirmed): `Base` and `get_db`.
- `alembic/versions/0001_initial.py` (confirmed): the only migration, revision `"0001"`.
- `tests/conftest.py` (confirmed): `db` fixture runs `create_all` and seeds user id 1. `client` overrides `get_db` and sends `X-User-Id: 1`.
- `tests/test_notes.py` (confirmed): one test (`test_create_and_list`).
- `CLAUDE.md` (confirmed) conventions: schema changes go through Alembic only. One router file per resource. Schemas live in `app/schemas.py`. Tests use pytest with the `client` and `db` fixtures.

## 4. Proposed Approach

- **Storage:** normalized tables. `tags(id, owner_id FK, name)` with `UNIQUE(owner_id, name)`. `note_tags(note_id FK, tag_id FK)` with PK `(note_id, tag_id)` and an index on `tag_id`. `Note.tags` is a many-to-many relationship. `Note.tag_names` is a property returning sorted names for the schema.
- **Alternative considered:** a JSON array column on `notes`. The migration is simpler, but filtering becomes JSON querying that differs by database, and there is no per-user tag list. Rejected.
- **Normalization:** a Pydantic validator in `app/schemas.py` strips, lowercases, dedupes, and checks each tag (1–50 chars, `[a-z0-9_-]`) and the count (max 20 per note). The same function normalizes the `tag` query parameter, so `?tag=Work` matches `work`.
- **Persistence:** get-or-create the owner's `Tag` rows in the router. The helper lives in `app/routers/notes.py` because the project has no services layer.
- **Query:** `list_notes` joins `note_tags` to `tags` and filters on `tags.owner_id == user.id` and `tags.name`. It uses `selectinload(Note.tags)` to avoid N+1 queries.

## 5. Scope

### In Scope

- Tags on create, replace-tags endpoint, tag filter on list, normalization, migration, tests.

### Out of Scope

- Multi-tag filtering (AND/OR), a `GET /tags` listing, tag rename or delete, tag colors, title/body search, note update or delete, real token auth, UI.

## 6. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `app/models.py` | confirmed | Add `Tag`, `note_tags`, `Note.tags`, `Note.tag_names` |
| `app/schemas.py` | confirmed | `NoteCreate.tags`, `NoteOut.tags`, `NoteTagsUpdate`, tag validator |
| `app/routers/notes.py` | confirmed | Create with tags, `tag` filter, `PUT /notes/{note_id}/tags`, get-or-create helper |
| `alembic/versions/0002_note_tags.py` | proposed | Create `tags` and `note_tags`, `down_revision = "0001"` |
| `tests/test_notes.py` | confirmed | New tests for T3–T6 |
| `alembic/env.py` | TBD | Missing from the project; see Open Questions Q1 |

## 7. Implementation Tasks

### T1 — Tag models

- [ ] **Objective:** Add the `Tag` model, the `note_tags` association table, and the `Note.tags` and `Note.tag_names` members.
- **Files:** `app/models.py` (confirmed)
- **Depends on:** None
- **Acceptance criteria:**
  - `Base.metadata` contains `tags` and `note_tags`.
  - `UNIQUE(owner_id, name)` is enforced.
  - A note with no tags has `tag_names == []`.
  - `tag_names` is sorted.
- **Tests:**
  - Same tag name for two owners is allowed.
  - Duplicate name for one owner raises `IntegrityError`.

### T2 — Migration 0002

- [ ] **Objective:** Create `tags` and `note_tags` in a reversible Alembic revision that matches T1.
- **Files:** `alembic/versions/0002_note_tags.py` (proposed)
- **Depends on:** T1
- **Acceptance criteria:**
  - Upgrading from `0001` creates both tables with the same columns, PK, FKs, unique constraint, and index as T1.
  - Downgrade drops `note_tags` before `tags`.
  - No backfill is needed.
- **Tests:**
  - Upgrade and downgrade round-trip on a temporary SQLite file. This requires the Alembic environment (Q1).

### T3 — Schemas and tag validation

- [ ] **Objective:** Add the tag fields and the shared normalization validator to `app/schemas.py`.
- **Files:** `app/schemas.py` (confirmed)
- **Depends on:** None
- **Acceptance criteria:**
  - `NoteCreate.tags: list[str] = []`.
  - `NoteOut.tags: list[str]`, filled from `tag_names`.
  - `NoteTagsUpdate` has `tags: list[str]`.
  - Invalid tags (length, characters, count) raise a validation error, which FastAPI returns as 422.
- **Tests:**
  - `"  Work "` becomes `"work"`.
  - `"a b"`, a 51-character tag, and 21 tags each fail validation.

### T4 — Create note with tags

- [ ] **Objective:** `POST /notes` persists tags, reusing the owner's existing `Tag` rows.
- **Files:** `app/routers/notes.py` (confirmed)
- **Depends on:** T1, T3
- **Acceptance criteria:**
  - `tags` is popped from the payload before `Note(...)` is constructed.
  - The response includes normalized, sorted tags.
  - No duplicate `tags` rows are created for an existing owner tag.
  - The existing `test_create_and_list` passes unchanged.
- **Tests:**
  - `["Work", "work", "home"]` returns `["home", "work"]`.
  - A second note with `"work"` does not add a `tags` row.
  - An invalid tag returns 422 and creates no note.

### T5 — Filter list by tag

- [ ] **Objective:** `GET /notes?tag=<name>` returns only the caller's matching notes.
- **Files:** `app/routers/notes.py` (confirmed)
- **Depends on:** T1, T4
- **Acceptance criteria:**
  - Results are newest first and limited to the caller's notes.
  - An unknown tag returns `[]` with 200.
  - Without `tag`, behavior is unchanged.
  - A repeated `tag` parameter returns 422.
  - `selectinload(Note.tags)` is used.
- **Tests:**
  - Filtering returns only matching notes.
  - Another user's note with the same tag name is excluded. Seed user id 2 inside the test.
  - `?tag=Work` matches `work`.

### T6 — Replace a note's tags

- [ ] **Objective:** `PUT /notes/{note_id}/tags` replaces the full tag set.
- **Files:** `app/routers/notes.py` (confirmed)
- **Depends on:** T4 (shared get-or-create helper)
- **Acceptance criteria:**
  - The response is `NoteOut` with the new tags.
  - `[]` clears all tags.
  - A missing note or another user's note returns 404, with no difference between the two.
- **Tests:**
  - Replace, then clear.
  - 404 for another user's note.
  - 404 for a missing note.

## 8. Testing Strategy

- Runner: pytest. `pyproject.toml` sets `testpaths = ["tests"]` and the dev extras are `pytest>=8` and `httpx>=0.27`. Command: `pytest`.
- Unit tests cover the validator (T3) and model constraints (T1). Integration tests use `TestClient` through the `client` fixture (T4–T6).
- The `db` fixture seeds only user 1. Tests for isolation seed user 2 inline.
- Edge cases: whitespace and case duplicates, the tag count limit, unknown filter values, cross-user access.
- Migration is tested per T2 once Q1 is resolved.

## 9. Security and Data Considerations

- **Ownership:** every tag and note query filters on `owner_id == user.id`. `PUT` returns 404 for notes the caller does not own.
- **Input:** tags are bounded by length, character set, and count. The ORM uses bound parameters.
- **Migration:** additive, no backfill. The downgrade drops tag data, which is acceptable only if the team agrees.
- **Compatibility:** `NoteOut.tags` and `NoteCreate.tags` are additive and optional.
- **Concurrency:** two simultaneous creates of the same new tag for one owner can hit the unique constraint. Catch `IntegrityError`, re-select, and retry once.
- **Auth:** isolation relies on the placeholder `X-User-Id` header in `app/auth.py`. This feature does not change that.

## 10. Risks and Assumptions

- **Assumption:** tags are lowercased, limited to `[a-z0-9_-]`, at most 50 characters, and at most 20 per note.
- **Assumption:** tags are owned per user.
- **Assumption:** the filter takes one tag. Multi-tag semantics are out of scope.
- **Assumption:** on replace or clear, orphaned `tags` rows are kept.
- **Risk:** no `alembic/env.py` exists, so `alembic upgrade head` cannot run. **Mitigation:** Q1.
- **Risk:** the placeholder auth makes isolation only as strong as the header check. **Mitigation:** out of scope; track separately.

## 11. Open Questions

1. **Q1:** `alembic/env.py` is missing (the file listing shows only `alembic.ini` and `0001_initial.py`). Should T2 add a standard `env.py`, or does Alembic run from another location?
2. **Q2:** Must tags be editable on existing notes, which R2 and T6 assume, or only at creation?
3. **Q3:** Should multi-tag filtering (AND/OR) be in this feature? The plan defers it.

## 12. Definition of Done

- [ ] T1–T6 complete and `pytest` passes
- [ ] `test_create_and_list` passes unchanged
- [ ] Migration 0002 upgrades and downgrades cleanly (after Q1)
- [ ] Cross-user isolation tests pass
- [ ] Lint and type checks: none configured in `pyproject.toml`, so not applicable
